pragma solidity ^0.4.13;

contract DSAuth {
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
    }


    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        }
        return false;
    }
}