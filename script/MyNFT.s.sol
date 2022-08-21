// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";

address constant GOERLI_VRF_COORDINATOR = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
uint64 constant GOERLI_VRF_SUBSCRIPTION_ID = 423;

contract MyNFTScript is Script {
    function run() public {
        vm.startBroadcast();
        new MyNFT(GOERLI_VRF_COORDINATOR, GOERLI_VRF_SUBSCRIPTION_ID);
        vm.stopBroadcast();
    }
}
