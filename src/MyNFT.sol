// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {VRFConsumerBaseV2} from "chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract MyNFT is ERC721, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using Strings for uint8;

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // each element of the set uint8 maps to an item class (0 no class).
    mapping(uint256 => uint8) private tokenIdToItemClass;
    mapping(uint256 => address) private requestIdToSender;

    Counters.Counter private _tokenIdCounter;

    event LogReceivedRandomness(uint256 reqId, uint8 num);
    event LogRequestedRandomness(uint256 reqId, address invoker);

    constructor(address _vrfCoordinator, uint64 _subscriptionId)
        ERC721("My NFT", "NFT")
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = _subscriptionId;
    }

    function safeMint() public returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit LogRequestedRandomness(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        uint256 randomWord = randomWords[0];
        // number in range from 1 to 255
        uint8 itemClass = uint8((randomWord % 255) + 1);

        address sender = requestIdToSender[requestId];

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(sender, tokenId);

        emit LogReceivedRandomness(requestId, itemClass);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        ownerOf(tokenId);

        uint8 itemClass = tokenIdToItemClass[tokenId];

        return
            string(
                abi.encodePacked(
                    "https://www.my-website.xyz/",
                    itemClass.toString()
                )
            );
    }
}
