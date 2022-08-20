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
    address payable internal someUser;

    event LogRequestedRandomness(uint256 reqId, address invoker);

    function setUp() public {
        // SET UP ACCOUNTS
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(3);
        ownerOfVRF = users[0];
        ownerNFTProject = users[1];
        someUser = users[2];

        vm.label(ownerOfVRF, "Owner of VRF");
        vm.label(ownerNFTProject, "Owner of NFT Project");
        vm.label(someUser, "User");

        vm.prank(ownerOfVRF);
        vrfCoordinator = new VRFCoordinatorV2Mock(0, 0);

        vm.startPrank(ownerNFTProject);
        uint64 subscriptionId = vrfCoordinator.createSubscription();
        myNFT = new MyNFT(address(vrfCoordinator), subscriptionId);
        vrfCoordinator.fundSubscription(subscriptionId, 1 ether);
        vrfCoordinator.addConsumer(subscriptionId, address(myNFT));
        vm.stopPrank();
    }

    function testEmitRequestedRandomnessWhenMinting() public {
        vm.prank(someUser);
        vm.expectEmit(false, false, false, true, address(myNFT));
        // 1 because it is the first requestId
        emit LogRequestedRandomness(1, someUser);
        myNFT.safeMint();
    }
}
