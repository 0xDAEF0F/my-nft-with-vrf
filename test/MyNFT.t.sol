// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {VRFCoordinatorV2Mock} from "chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract MyNFTTest is Test {
    using Strings for uint8;

    VRFCoordinatorV2Mock vrfCoordinator;
    MyNFT myNFT;
    Utilities internal utils;
    address payable internal ownerOfVRF;
    address payable internal ownerNFTProject;
    address payable internal user;
    address payable internal hacker;

    event LogRequestedRandomness(uint256 reqId, address invoker);
    event LogReceivedRandomness(uint256 reqId, uint8 num);
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );

    function setUp() public {
        // SET UP ACCOUNTS
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(4);
        ownerOfVRF = users[0];
        ownerNFTProject = users[1];
        user = users[2];
        hacker = users[3];

        vm.label(ownerOfVRF, "Owner of VRF");
        vm.label(ownerNFTProject, "Owner of NFT Project");
        vm.label(user, "User");
        vm.label(hacker, "Hacker");

        vm.prank(ownerOfVRF);
        vrfCoordinator = new VRFCoordinatorV2Mock(0, 0);
        vm.label(address(vrfCoordinator), "VRFCoordinator");

        vm.startPrank(ownerNFTProject);
        uint64 subscriptionId = vrfCoordinator.createSubscription();
        myNFT = new MyNFT(address(vrfCoordinator), subscriptionId);
        vm.label(address(myNFT), "NFT Contract");
        vrfCoordinator.fundSubscription(subscriptionId, 1 ether);
        vrfCoordinator.addConsumer(subscriptionId, address(myNFT));
        vm.stopPrank();
    }

    function testMyNFTShouldRequestRandomness() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true, address(myNFT));
        // 1 because it is the first requestId
        emit LogRequestedRandomness(1, user);
        myNFT.safeMint();
        vm.stopPrank();
    }

    function testCoordShouldEmitRandWordsRequested() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true, address(vrfCoordinator));
        emit RandomWordsRequested(
            bytes32(
                0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
            ),
            1,
            100,
            1,
            3,
            200000,
            1,
            address(myNFT)
        );
        myNFT.safeMint();
        vm.stopPrank();
    }

    function testMyNFTShouldReceiveRandomWord() public {
        vm.prank(user);
        uint256 requestId = myNFT.safeMint();

        vm.expectEmit(true, true, true, true);
        emit LogReceivedRandomness(1, 12);

        vm.prank(ownerOfVRF);
        vrfCoordinator.fulfillRandomWords(requestId, address(myNFT));
    }

    function setMintProcess(uint256 randomWord) private {
        uint256[] memory arr = new uint256[](1);
        arr[0] = randomWord;

        vm.prank(user);
        uint256 requestId = myNFT.safeMint();

        vm.prank(ownerOfVRF);
        vrfCoordinator.fulfillRandomWordsWithOverride(
            requestId,
            address(myNFT),
            arr
        );
    }

    function testOwnerOfNFTShouldBeMinter(uint256 randomWord) public {
        setMintProcess(randomWord);

        address ownerOfTokenZero = myNFT.ownerOf(0);

        assertEq(ownerOfTokenZero, user);
    }

    function testMintedTokenShouldCorrespondToAnItemClass(uint256 randomWord)
        public
    {
        setMintProcess(randomWord);

        uint8 tokenClass = myNFT.tokenIdToItemClass(0);

        assertEq(
            string(
                abi.encodePacked(
                    "https://www.my-website.xyz/",
                    tokenClass.toString()
                )
            ),
            myNFT.tokenURI(0)
        );
        // item class should be in range 1 - 255
        assertTrue(tokenClass > 0 && tokenClass < 256);
    }

    function testHackerShouldNotBeAbleToTransferToken(uint256 randomWord)
        public
    {
        setMintProcess(randomWord);

        vm.expectRevert(bytes("NOT_AUTHORIZED"));
        myNFT.safeTransferFrom(user, hacker, 0);
    }
}
