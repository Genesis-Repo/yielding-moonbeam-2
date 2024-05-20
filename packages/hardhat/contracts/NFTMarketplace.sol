// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Address for address payable;

    struct Sale {
        uint256 tokenId;
        address seller;
        uint256 price;
        uint256 royaltyPercentage; // New feature: Royalty percentage
        bool active;
    }

    mapping(uint256 => Sale) public nftSales;

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price, uint256 royaltyPercentage); // Updated event with royaltyPercentage
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function listNFT(uint256 tokenId, uint256 price, uint256 royaltyPercentage) external {
        require(_exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        nftSales[tokenId] = Sale(tokenId, msg.sender, price, royaltyPercentage, true);
        emit NFTListed(tokenId, msg.sender, price, royaltyPercentage);
    }

    function buyNFT(uint256 tokenId) external payable nonReentrant {
        Sale memory sale = nftSales[tokenId];
        require(sale.active, "NFT not available for sale");
        require(msg.value >= sale.price, "Insufficient funds sent");

        address payable seller = payable(sale.seller);
        seller.sendValue(msg.value);

        // Transfer royalty percentage to the creator
        uint256 royaltyAmount = (msg.value * sale.royaltyPercentage) / 100;
        payable(ownerOf(tokenId)).sendValue(royaltyAmount);

        _transfer(seller, msg.sender, tokenId);
        nftSales[tokenId].active = false;

        emit NFTSold(tokenId, msg.sender, sale.price);
    }

    function setNFTPrice(uint256 tokenId, uint256 price) external {
        require(_exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        nftSales[tokenId].price = price;
    }

    function setRoyaltyPercentage(uint256 tokenId, uint256 newRoyaltyPercentage) external {
        require(_exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        nftSales[tokenId].royaltyPercentage = newRoyaltyPercentage;
    }

    function removeNFTListing(uint256 tokenId) external {
        require(_exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        delete nftSales[tokenId];
    }
}