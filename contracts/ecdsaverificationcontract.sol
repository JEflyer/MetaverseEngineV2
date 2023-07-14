//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IStats {
    function incrementWins(uint256 tokenID, address minter) external;

    function incrementLosses(uint256 tokenID, address minter) external;
}

contract ECDSAVerificationContract is Ownable {
    mapping (address => mapping(address  => uint)) public nonces;

    address statsContract;

    constructor(address stats){
        statsContract = stats;
    }

    function verify(bytes[3] memory signatures, uint256[2] memory tokenIDs, address[2] memory minters,address[2] memory players) external  {

        require(IERC721(minters[0]).ownerOf(tokenIDs[0]) == players[0],"ERR:Minter does not own token");
        require(IERC721(minters[1]).ownerOf(tokenIDs[1]) == players[1],"ERR:Minter does not own token");

        uint nonce = nonces[players[0]][players[1]];
        
        bytes32 firstHashedMessage = keccak256(abi.encodePacked(
            tokenIDs,
            minters,
            nonce,
            false
        ));

        bytes32 secondHashedMessage = keccak256(abi.encodePacked(
            tokenIDs,
            minters,
            nonce,
            true
        ));

        bool checkFirst = verifySignature(players[0], firstHashedMessage, signatures[0]);
        require(checkFirst,"ERR:FS");//FS => First Signature

        bool checkSecond = verifySignature(players[1], firstHashedMessage, signatures[1]);
        require(checkSecond,"ERR:SS");//SS => Second Signer

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(secondHashedMessage);
        address winner = ECDSA.recover(messageHash, signatures[2]);

        uint256 winningTokenID;
        address winningMinter;

        
        uint256 losingTokenID;
        address losingMinter;

        if(winner == players[0]){
            winningMinter = minters[0];
            winningTokenID = tokenIDs[0];

            losingMinter = minters[1];
            losingTokenID = tokenIDs[1];

        }else if(winner == players[1]){
            winningMinter = minters[1];
            winningTokenID = tokenIDs[1];

            losingMinter = minters[0];
            losingTokenID = tokenIDs[0];
        }else {
            revert("ERR:InvalidWinner");
        }

        nonces[players[0]][players[1]]++;
        nonces[players[1]][players[0]]++;

        IStats(statsContract).incrementLosses(losingTokenID,losingMinter);
        IStats(statsContract).incrementWins(winningTokenID,winningMinter);

    }

    function verifySignature(address signer, bytes32 hash, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(hash);
        address recoveredSigner = ECDSA.recover(messageHash, signature);
        return recoveredSigner == signer;
    }

    function getNonce(address a, address b) external view returns(uint256){
        return nonces[a][b];
    }
}
