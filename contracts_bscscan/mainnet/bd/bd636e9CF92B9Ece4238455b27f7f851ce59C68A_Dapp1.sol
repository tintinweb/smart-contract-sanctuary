/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity 0.8.0;

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

        require(b > 0);

        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract Dapp1 is Ownable {
    
    IBEP20 fastTrack;
    address payable wallet;
    
    constructor(IBEP20 _fastTrack, address payable _wallet){
       fastTrack=_fastTrack;
       wallet=_wallet;
    }
    
    function swapTokens() public payable { 

        require(msg.value>=0.01 ether && msg.value<=3 ether,"Please enter BNB in valid range!");
        
        uint256 tokens=getTokens(msg.value);
        wallet.transfer(msg.value);
        fastTrack.transfer(msg.sender,tokens);
        
    }
    
    function getTokens(uint256 _amountOfBNB) public pure returns(uint256){
        uint256 tokens=SafeMath.div(SafeMath.mul(_amountOfBNB,35000),10**9);
        return tokens;
    }

}