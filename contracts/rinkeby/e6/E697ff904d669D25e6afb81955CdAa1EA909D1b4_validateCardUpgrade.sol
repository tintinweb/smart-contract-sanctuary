pragma solidity ^0.7.5;

import "../interfaces/traitsOnChain.sol";
import "./Ivalidator.sol";
contract validateCardUpgrade is Ivalidator {

    uint16  constant public trait_AlphaUpgrade = 5;
    uint16  constant public trait_OGUpgrade    = 6;


    TraitsOnChain                 public     _toc;
    address                       public     token;
    mapping (uint256 => uint256)  public     validTokens;

    constructor(TraitsOnChain toc,address _token) {
        token = _token;
        _toc = toc;
    }

//
// function setTrait(uint16 traitID, uint16 tokenId, bool _value) public onlyAllowedOrSpecificTraitController(traitID) {
// function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result) {
// traits 0 - 50

    function is_valid(address _token, uint256 tokenid) external override returns (uint256,bool) {
        // get traits of card
        if (_token != token) return (0,false);
        if (tokenid < 1000) return (0,false);
        uint16 _tokenid = uint16(tokenid);
        //
        if (_toc.hasTrait(trait_AlphaUpgrade,_tokenid)) {
            _toc.setTrait(trait_AlphaUpgrade,_tokenid,false);
            return (1,true);
        } else if (_toc.hasTrait(trait_OGUpgrade,_tokenid)) {
            _toc.setTrait(trait_OGUpgrade,_tokenid,false);
            return (0,true);
        } else return (0,false);
    }
}

pragma solidity ^0.7.0;


interface TraitsOnChain {
    function hasTrait(uint16 traitID, uint16 tokenId) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external;
}

pragma solidity ^0.7.5;


interface Ivalidator {
    function is_valid(address _token, uint256 _tokenid) external returns (uint256,bool);
}

