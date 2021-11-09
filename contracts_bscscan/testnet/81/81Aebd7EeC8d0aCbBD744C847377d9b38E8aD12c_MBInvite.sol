pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./InviteInterface.sol";

contract MBInvite is Ownable, IMBInvite {
    constructor() {}

    // map store the invitor of the address
    mapping(address => address) public inviteMap;
    mapping(address => uint256) public inviteCounts;
    mapping(address => mapping(address=>uint256)) public inviteDividends;
    mapping(address => address[]) public userAllInvites;
    address[] public supportTokens;
    uint256 supportTokenLen = 0;
    mapping(address=>bool) public supportTokenMap;
    
    struct TokenDivids {
        address token;
        uint256 amount;
    }
    
    
    // address which can call update
    mapping(address => bool) public allowAddresses;

    // max to 10000;
    uint256 private _inviteFeePercent = 500; // 5%
    uint256 maxFeePercent = 10000; // 100%

    function setInviteFee(uint256 _fee) public onlyOwner {
        require(_inviteFeePercent <= maxFeePercent, "fee reach max");
        _inviteFeePercent = _fee;
    }

    function inviteFeePercent() public view override returns (uint256) {
        return _inviteFeePercent;
    }

    function getInvitor(address _addr) public view override returns (address)  {
        return inviteMap[_addr];
    }
    
    function addSupportToken(address _token) public onlyOwner {
        for(uint256 i = 0; i <supportTokenLen; i++) {
            require(supportTokens[i] != _token, "the token has already in list");
        }
        supportTokenLen++;
        supportTokens.push(_token);
        supportTokenMap[_token] = true;
    }

    event UserInviteEvent(
        address indexed user,
        address indexed invitor,
        uint256 num
    );

    function setUserInvitor(address _from) public {
        require(_from != msg.sender, "user can not set your self as invitor");
        require(!userHasInvited(msg.sender), "user has already inivted");
        // set users invitor
        inviteMap[msg.sender] = _from;
        // add counts
        inviteCounts[_from]++;
        // save invitors invite info
        userAllInvites[_from].push(msg.sender);
        // save log
        emit UserInviteEvent(msg.sender, _from, inviteCounts[_from]);
    }

    function userHasInvited(address _from) public view returns (bool) {
        return inviteMap[_from] != address(0);
    }

    function getMyInvitor() public view returns (address) {
        return inviteMap[msg.sender];
    }

    struct UserInviteInfo {
        address user;
        TokenDivids[] inviteDividends;
    }

    function getAllUserInvites(address user)
        public
        view
        returns (UserInviteInfo[] memory)
    {
        uint256 count = inviteCounts[user];
        UserInviteInfo[] memory _ret = new UserInviteInfo[](count);
        
        for (uint256 i = 0; i < count; i++) {
            address cur = userAllInvites[user][i];
            TokenDivids[] memory temp = new TokenDivids[](supportTokenLen);
            for(uint256 j = 0; j < supportTokenLen; j ++) {
                temp[j] = TokenDivids(supportTokens[j],inviteDividends[supportTokens[j]][cur]);
            }    
            _ret[i] = UserInviteInfo(cur, temp);
        }
        return _ret;
    }
    
    function updateAllowAddress(address _addr, bool _enabled) public onlyOwner {
        allowAddresses[_addr] = _enabled;
    }
    
    function bulkUpdateAllowAddress(address[] calldata _addr_list, bool[] calldata _enabled_list) public onlyOwner {
        for(uint8 i = 0; i<_addr_list.length; i++ ) {
            allowAddresses[_addr_list[i]] = _enabled_list[i];
        }
        
    }


    // update the divided amout of the user
    function updateDividen(address _addr,address _token, uint256 _amount) public override {
        require(allowAddresses[msg.sender], "you shall not pass");
        if(userHasInvited(_addr)) {
            inviteDividends[_token][_addr] += _amount;
        }
    }
}