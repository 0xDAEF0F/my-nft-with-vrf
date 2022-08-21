// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {VRFCoordinatorV2Mock} from "chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Utilities} from "./utils/Utilities.sol";

contract MyNFTTest is Test {
    VRFCoordinatorV2Mock vrfCoordinator;
    MyNFT myNFT;
    Utilities internal utils;
    address payable internal ownerOfVRF;
    address payable internal ownerNFTProject;
    address payable internal user;

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
        address payable[] memory users = utils.createUsers(3);
        ownerOfVRF = users[0];
        ownerNFTProject = users[1];
        user = users[2];

        vm.label(ownerOfVRF, "Owner of VRF");
        vm.label(ownerNFTProject, "Owner of NFT Project");
        vm.label(user, "User");

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
}
