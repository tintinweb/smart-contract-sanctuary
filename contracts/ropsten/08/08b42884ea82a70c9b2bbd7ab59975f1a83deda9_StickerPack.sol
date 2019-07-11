pragma solidity >=0.5.0 <0.6.0;

import "./ERC721Full.sol";
import "./Controlled.sol";
import "./TokenClaimer.sol";

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract StickerPack is Controlled, TokenClaimer, ERC721Full("Sticker Pack","STKP") {

    mapping(uint256 => uint256) public tokenPackId; //packId
    uint256 public tokenCount; //tokens buys

    /**
     * @notice controller can generate tokens at will
     * @param _owner account being included new token
     * @param _packId pack being minted
     * @return tokenId created
     */
    function generateToken(address _owner, uint256 _packId)
        external
        onlyController
        returns (uint256 tokenId)
    {
        tokenId = tokenCount++;
        tokenPackId[tokenId] = _packId;
        _mint(_owner, tokenId);
    }

    /**
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token)
        external
        onlyController
    {
        withdrawBalance(_token, controller);
    }



}