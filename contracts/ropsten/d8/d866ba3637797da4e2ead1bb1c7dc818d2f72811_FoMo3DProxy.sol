pragma solidity ^0.4.24;

interface FoMo3DLongInterface {
    function buyXid(uint256 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256);
    function buyXaddr(address _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256);
    function buyXname(bytes32 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256);

    function registerNameXid(string memory _nameString, uint256 _affCode, bool _all) public;
    function registerNameXaddr(string memory _nameString, address _affCode, bool _all) public;
    function registerNameXname(string memory _nameString, bytes32 _affCode, bool _all) public;
    
    function getBuyPrice() public returns(uint256);
    function getTimeLeft() public returns(uint256);

    function getCurrentRoundInfo() public returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function getPlayerInfoByAddress(address _addr) public view returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function getPlayerRoundInfoByID(uint256 _pID, uint256 _rID) public view returns(uint256, uint256, bool, uint256, uint256, uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256);
    function getCurrentRoundTeamCos() public view returns(uint256,uint256,uint256,uint256);
    
    function sellKeys(uint256 _pID_, uint256 _keys_, bytes32 _keyType) public returns(uint256);
    function playGame(uint256 _pID, uint256 _keys, uint256 _team, bytes32 _keyType) public returns(bool,bool);
    function buyProp(uint256 _pID, uint256 _eth, uint256 _propID) public returns(uint256,uint256);
    function buyLeader(uint256 _pID, uint256 _eth) public returns(uint256,uint256);
    function iWantXKeys(uint256 _keys) public returns(uint256);
    
    function withdrawHoldVault(uint256 _pID) public returns(bool);
    function withdrawAffVault(uint256 _pID) public returns(bool);
    function withdrawWonCosFromGame(uint256 _pID, uint256 _affID, uint256 _rID) public returns(bool);
    function transferToAnotherAddr(address _from, address _to, uint256 _keys, bytes32 _keyType) public returns(bool);
    function activate() public;
}

contract FoMo3DProxy {
    //    otherFoMo3D private otherF3D_;
    FoMo3DLongInterface constant private FoMo3DLong = FoMo3DLongInterface(0x7403F33CaD5FBCb6EDbdC3D5d2Cb48e4B9b8c339);

     //==============================================================================
    //     _ _  _  |`. _     _ _ |_ | _  _  .
    //    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
    //=================_|===========================================================
    string constant public name = "FoMo3D Proxy";
    string constant public symbol = "F3DP";

    constructor()
    public
    {

    }

    function buyXid(uint256 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256){
        return FoMo3DLong.buyXid(_affCode, _eth, _keyType);
    }
    function buyXaddr(address _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256){
        return FoMo3DLong.buyXaddr(_affCode,  _eth, _keyType);
    }
    // function _buyXname(bytes32 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256){
    //     return FoMo3DLong.buyXname(_affCode,  _eth, _keyType);
    // }


    function registerNameXid(string memory _nameString, uint256 _affCode, bool _all) public{
        FoMo3DLong.registerNameXid(_nameString, _affCode, _all);
    }
    function registerNameXaddr(string memory _nameString, address _affCode, bool _all) public{
        FoMo3DLong.registerNameXaddr(_nameString, _affCode, _all);
    }
    // function _registerNameXname(string memory _nameString, bytes32 _affCode, bool _all) public{
    //     FoMo3DLong.registerNameXname(_nameString, _affCode, _all);
    // }

    
    function getBuyPrice() public returns(uint256){
        return FoMo3DLong.getBuyPrice();
    }
    function getTimeLeft() public returns(uint256){
        return FoMo3DLong.getTimeLeft();
    }

    function getCurrentRoundInfo() public returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        return FoMo3DLong.getCurrentRoundInfo();
    }
    function getPlayerInfoByAddress(address _addr) public returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        return FoMo3DLong.getPlayerInfoByAddress(_addr);
    }
    function getCurrentRoundTeamCos() public view returns(uint256,uint256,uint256,uint256){
        return FoMo3DLong.getCurrentRoundTeamCos();
    }
    
    function sellKeys(uint256 _pID_, uint256 _keys_, bytes32 _keyType) public returns(uint256){
        return FoMo3DLong.sellKeys(_pID_, _keys_, _keyType);
    }
    function playGame(uint256 _pID, uint256 _keys, uint256 _team, bytes32 _keyType) public returns(bool,bool){
        return FoMo3DLong.playGame(_pID, _keys, _team, _keyType);
    }

    function buyProp(uint256 _pID, uint256 _eth, uint256 _propID) public returns(uint256,uint256){
        return FoMo3DLong.buyProp(_pID, _eth,_propID);
    }
    function buyLeader(uint256 _pID, uint256 _eth) public returns(uint256,uint256){
        return FoMo3DLong.buyLeader(_pID, _eth);
    }
    function iWantXKeys(uint256 _keys) public returns(uint256){
        return FoMo3DLong.iWantXKeys(_keys);
    }
    
    function withdrawHoldVault(uint256 _pID) public returns(bool){
        return FoMo3DLong.withdrawHoldVault(_pID);
    }
    function withdrawAffVault(uint256 _pID) public returns(bool){
        return FoMo3DLong.withdrawAffVault(_pID);
    }

    function withdrawWonCosFromGame(uint256 _pID, uint256 _affID, uint256 _rID) public returns(bool){
        return FoMo3DLong.withdrawWonCosFromGame(_pID, _affID, _rID);
    }

    function transferToAnotherAddr(address _from, address _to, uint256 _keys, bytes32 _keyType) public returns(bool){
        return FoMo3DLong.transferToAnotherAddr(_from, _to, _keys, _keyType);
    }

    function activate() public{
        FoMo3DLong.activate();
    }

}