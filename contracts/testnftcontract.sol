//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

//Using a basic ERC721 minter
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//Using the Ownable library for simple owner privilledge functionality
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestNFTContract is ERC721, Ownable {

    //On deployment instantiate the ERC721 contract constructor with the name of TestNFT & symbol of TNFT
    constructor() ERC721("TestNFT", "TNFT") {}

    //This function is used to mint NFTs to an address with a given tokenId
    function mint(address to, uint tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

}
