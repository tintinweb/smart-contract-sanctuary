//SourceUnit: trc10.sol

pragma solidity 0.5.9;

contract Funzoo {
    struct User {
        uint256 Id;
        address upline;
        uint256 referrals;
        uint256 deposit_amount;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 lastDepositId;
    }

    address payable public owner;

    mapping(address => User) public users;
    mapping(bytes32 => mapping(uint256 => bool)) public seenNonces;
    trcToken tokenId=1002000;
    uint256[] public levels;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    address signatureAddress;
    uint256 public last_id;
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed sender,address indexed receiver, uint256 amount);

    constructor(address payable _owner) public {
        levels.push(200 trx);
        levels.push(140 trx);
        levels.push(360 trx);
        levels.push(1200 trx);
        levels.push(5000 trx);
        levels.push(27000 trx);
        levels.push(168000 trx);
        owner = _owner;
        users[owner].Id=last_id;
        signatureAddress = _owner;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"onlyOwner can call!");
        _;
    }
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

        }
    }

    function _deposit(uint256 _value, address _addr, uint256 _packageId) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(_value == levels[_packageId], "Invalid amount");
        users[_addr].deposit_amount = _value;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits +=  _value;
        users[_addr].Id = ++last_id;
        total_deposited += _value;
        users[_addr].lastDepositId++;
        emit NewDeposit(_addr,  _value);
    }

    function register(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.tokenvalue,msg.sender,0);
    }
    
    function upgradePackage() payable external {
         require(users[msg.sender].Id>0,"You have to register first");
         require(users[msg.sender].lastDepositId<levels.length,"You have purchased all packages");
        _deposit(msg.tokenvalue,msg.sender,users[msg.sender].lastDepositId);
    }
     function isSigned(
        address _addr,
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        return ecrecover(msgHash, v, r, s) == _addr;
    }
        function userTokenWithdraw(
        uint256 amount,
        uint256 nonce,
        bytes32[] memory msgHash_r_s,
        uint8 v
    ) public {
        // Signature Verification
        require(
            isSigned(
                signatureAddress,
                msgHash_r_s[0],
                v,
                msgHash_r_s[1],
                msgHash_r_s[2]
            ),
            "Signature Failed"
        );
        // Duplication check
        require(seenNonces[msgHash_r_s[0]][nonce] == false);
        seenNonces[msgHash_r_s[0]][nonce] = true;
        // Token Transfer
        msg.sender.transferToken(amount,tokenId);
        emit Withdraw(address(this), msg.sender, amount);
    }
     function changeSigAddress(address _sigAddress) public onlyOwner {
        signatureAddress = _sigAddress;
    }
    /*
        Only external call
    */
}