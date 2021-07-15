/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Token {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint256);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract lockToken is owned{
    using SafeMath for uint256;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    /*
     * deposit vars
    */
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    struct TokensBalances{
        address tokenAddress;
        uint256 tokenBalance;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping (address => uint256[]) public depositsByWithdrawalAddress;
    mapping (uint256 => Items) public lockedToken;
    mapping (address => mapping(address => uint256)) public walletTokenBalance;

    event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);

    /**
     * Constrctor function
    */
    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     *lock tokens
    */
    function lockTokens(address[] memory _tokenAddress, uint256[] memory _amount, uint256[] memory _unlockTime) public returns (uint256 _id) {
        for(uint i = 0; i < _tokenAddress.length; i++) {
            uint256 amount = _amount[i].mul(10**Token(_tokenAddress[i]).decimals());
            require(amount > 0, 'token amount is Zero');
            require(_unlockTime[i] < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
            require(Token(_tokenAddress[i]).approve(address(this), amount), 'Approve tokens failed');
            require(Token(_tokenAddress[i]).transferFrom(msg.sender, address(this), amount), 'Transfer of tokens failed');

            //update balance in address
            walletTokenBalance[_tokenAddress[i]][msg.sender] = walletTokenBalance[_tokenAddress[i]][msg.sender].add(amount);

            address _withdrawalAddress = msg.sender;
            _id = ++depositId;
            lockedToken[_id].tokenAddress = _tokenAddress[i];
            lockedToken[_id].withdrawalAddress = _withdrawalAddress;
            lockedToken[_id].tokenAmount = amount;
            lockedToken[_id].unlockTime = _unlockTime[i];
            lockedToken[_id].withdrawn = false;

            allDepositIds.push(_id);
            depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        }
    }

    /**
     *withdraw tokens
    */
    function withdrawTokens(uint256 _id) nonReentrant public {
        require(block.timestamp >= lockedToken[_id].unlockTime, 'Tokens are locked');
        require(msg.sender == lockedToken[_id].withdrawalAddress, 'Can withdraw by withdrawal Address only');
        require(!lockedToken[_id].withdrawn, 'Tokens already withdrawn');
        lockedToken[_id].withdrawn = true;
        require(Token(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount), 'Transfer of tokens failed');



        //update balance in address
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);

        //remove this id from this address
        uint256 i; uint256 j;
        for(j=0; j<depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length; j++){
            if(depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id){
                for (i = j; i<depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length-1; i++){
                    depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][i] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][i+1];
                }
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length--;
                break;
            }
        }
        emit LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }

    /*get total token balance in contract*/
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
        return Token(_tokenAddress).balanceOf(address(this));
    }

    function getAllTokens() view public returns (TokensBalances[] memory)
    {
        uint256 size=depositId+1;
        TokensBalances[] memory tBalances=new TokensBalances[](depositId);
        for(uint256 i=1;i<size;i++){
            tBalances[i-1]=TokensBalances({
            tokenAddress:lockedToken[i].tokenAddress,
            tokenBalance:Token(lockedToken[i].tokenAddress).balanceOf(address(this))
            });
        }
        return(tBalances);
    }

    /*get total token balance by address*/
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
    {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    /*get allDepositIds*/
    function getAllDepositIds() view public returns (uint256[] memory)
    {
        return allDepositIds;
    }

    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (address, address, uint256, uint256, bool)
    {
        return(lockedToken[_id].tokenAddress,lockedToken[_id].withdrawalAddress,lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }

    function getLockedTokenDetails(address _tokenAddress) view public returns (Items[] memory)
    {
        uint256 size=depositId+1;
        Items[] memory data = new Items[](depositId);
        uint256 j=0;
        for(uint256 i=1;i<size;i++){
            if(lockedToken[i].tokenAddress==_tokenAddress){
                data[j]=lockedToken[i];
                j++;
            }
        }
        if(j>0){
            Items[] memory dataReturned = new Items[](j);
            for(uint256 i=0;i<j;i++){
                dataReturned[i]=data[i];
            }
            return(dataReturned);
        }
        return(data);
    }

    /*get DepositsByWithdrawalAddress*/
    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory)
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }
}