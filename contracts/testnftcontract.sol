//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestNFTContract is ERC721, Ownable {
    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to, uint tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
