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

    /*//////////////////////////////////////////////////////////////
                         VRF INFORMATION
    //////////////////////////////////////////////////////////////*/

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 immutable VRF_SUBSCRIPTION_ID;
    bytes32 constant VRF_KEY_HASH =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    /*//////////////////////////////////////////////////////////////
                         CUSTOM FUNCTIONALITY NFT
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => uint8) public tokenIdToItemClass;
    mapping(uint256 => address) private _requestIdToSender;
    Counters.Counter private _tokenIdCounter;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogReceivedRandomness(uint256 reqId, uint8 num);
    event LogRequestedRandomness(uint256 reqId, address invoker);

    constructor(address _vrfCoordinator, uint64 _subscriptionId)
        ERC721("My NFT", "NFT")
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        VRF_SUBSCRIPTION_ID = _subscriptionId;
    }

    function safeMint() public returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            VRF_KEY_HASH,
            VRF_SUBSCRIPTION_ID,
            // requestConfirmations
            3,
            // callbackGasLimit
            200000,
            // random words to request
            1
        );
        _requestIdToSender[requestId] = msg.sender;
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
        // person who requested the mint
        address sender = _requestIdToSender[requestId];
        // tokenId to mint
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(sender, tokenId);
        // assign a class to that token
        tokenIdToItemClass[tokenId] = itemClass;

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
