// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @dev Implementation of NFT marketplace for IVIRSE
 */
 
contract NftMarketplace is ERC1155, Ownable {
    uint256 private tokenId;
    mapping (uint256 => uint256) priceTokenId;
    mapping (uint256 => address) tokenIdToOwner;
    mapping (address => uint256[]) ownerToListTokenId;
    mapping (uint256 => bool) tradingStatus;
 
    constructor() ERC1155("") {
        tokenId = 0;
    }

    /**
    * @dev create an NFT asset for address `to`
    */
    function mint(address to) public onlyOwner{
        tokenIdToOwner[tokenId] = to;
        _mint(to, tokenId, 1, "");
        ownerToListTokenId[to].push(tokenId);
        tradingStatus[tokenId] = false;
        tokenId++;
    }

    /**
    * @dev destroy an NFT asset for address `from` with token `id`
    */
    function burn(address from, uint256 id) public{
        require(_msgSender() == from);
        _burn(from, id, 1);
        tradingStatus[tokenId] = false;
    }

    /**
     * @dev list a token of type `id` to sell.
     * set the price of token `id` equal to `price`
     * enable `tradingStatus` for selling token `id`
     * Requirements:
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function sellToken(uint256 id, uint256 price) public {
        require(_msgSender() == tokenIdToOwner[id], "only owner of this token can sell it");
        priceTokenId[id] = price;
        tradingStatus[id] = true;
    }

    /**
     * @dev buy a token of token type `id`.
     * give reassign token `id` to parties
     * process payment procedure
     * Requirements:
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function buyToken(uint256 id) external payable {
        require(msg.value >= priceTokenId[id], "Not enough money to buy this token");
        require(id <= tokenId, "Token does not exist");
        require(tradingStatus[id] == true, "Seller don't want to exchange this token");
    
        uint256 excessCash = msg.value - priceTokenId[id];
        address payable seller = payable(tokenIdToOwner[id]); 
        address payable buyer = payable(_msgSender());
        _safeTransferFrom(seller, _msgSender(), id, 1,""); // give token to buyer
        removeIdFromOwner(id); // remove token from seller list
        ownerToListTokenId[buyer].push(id);
        seller.transfer(priceTokenId[id]); // send money to seller
        buyer.transfer(excessCash); // give excess cash back to buyer
        tradingStatus[tokenId] = false;
    }

    /**
    * @dev remove a token `id` from owner
    */
    function removeIdFromOwner(uint256 id) private {
        uint256 i;
        uint256 mark;
        address _owner = tokenIdToOwner[id];
        uint256 listTokenLength = ownerToListTokenId[_owner].length;

        if(listTokenLength!=1){
            for (i = 0; i< listTokenLength; i++) {
                if(ownerToListTokenId[_owner][i] == id) {
                    mark = i;
                    break;
                }
            }

            for (i = mark; i< listTokenLength - 1; i++) {
                ownerToListTokenId[_owner][i] = ownerToListTokenId[_owner][i+1];
            }
        }
        ownerToListTokenId[_owner].pop();
    }

    /**
    * @dev return list of token `id` from an owner
    */
    function getTokenIdFromOwner(address owner) public view returns(uint256[] memory){
        return ownerToListTokenId[owner];
    }

    /**
    * @dev return number of token `id` from an owner
    */
    function getTokenIdCountFromOwner(address owner) public view returns(uint256) {
        return  ownerToListTokenId[owner].length;
    }
}