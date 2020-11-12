pragma solidity >0.5.99 <0.8.0;

    contract Owner
    {
        address private _owner;
        mapping(address=> bool) blacklist;
        event AddToBlackList(address _blacklisted);
        event RemoveFromBlackList(address _whitelisted);
        constructor() public 
        {
            _owner = msg.sender;
        }
        
        function getOwner() public view returns(address) { return _owner; }
        
        modifier isOwner()
        {
            require(msg.sender == _owner,'Your are not Authorized user');
            _;
            
        }
        
        modifier isblacklisted(address holder)
        {
            require(blacklist[holder] == false,"You are blacklisted");
            _;
        }
        
        function chnageOwner(address newOwner) isOwner() external
        {
            _owner = newOwner;
        }
        
        function addtoblacklist (address blacklistaddress) isOwner()  public
        {
            blacklist[blacklistaddress] = true;
            emit AddToBlackList(blacklistaddress);
        }
        
        function removefromblacklist (address whitelistaddress) isOwner()  public
        {
            blacklist[whitelistaddress]=false;
            emit RemoveFromBlackList(whitelistaddress);
        }
        
        function showstateofuser(address _address) public view returns (bool)
        {
            return blacklist[_address];
        }
    }
