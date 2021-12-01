//SourceUnit: BTT.sol

pragma solidity ^0.5.8;

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

}

contract BTT is ITRC20 {
    using SafeMath for uint256;
    string constant public name = "BitTorrent";
    string constant public symbol = "BTT";
    uint8 constant  public decimals = 18;

    uint256 private totalSupply_;
    mapping(address => uint256) private  balanceOf_;
    mapping(address => mapping(address => uint256)) private  allowance_;

    constructor(address fund) public {
        totalSupply_ = 9900 * 1e8 * 1e18 * 1e3;
        balanceOf_[fund] = totalSupply_;
        emit Transfer(address(0x00), fund, totalSupply_);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address guy) public view returns (uint256){
        return balanceOf_[guy];
    }

    function allowance(address src, address guy) public view returns (uint256){
        return allowance_[src][guy];
    }

    function approve(address guy, uint256 sad) public returns (bool) {
        allowance_[msg.sender][guy] = sad;
        emit Approval(msg.sender, guy, sad);
        return true;
    }

    function transfer(address dst, uint256 sad) public returns (bool) {
        return transferFrom(msg.sender, dst, sad);
    }

    function transferFrom(address src, address dst, uint256 sad)
    public returns (bool)
    {
        require(balanceOf_[src] >= sad, "src balance not enough");

        if (src != msg.sender && allowance_[src][msg.sender] != uint256(-1)) {
            require(allowance_[src][msg.sender] >= sad, "src allowance is not enough");
            allowance_[src][msg.sender] = allowance_[src][msg.sender].sub(sad, "allowance subtraction overflow") ;
        }
        balanceOf_[src] = balanceOf_[src].sub(sad, "from balance subtraction overflow");
        balanceOf_[dst] = balanceOf_[dst].add(sad, "to balance addition overflow") ;

        emit Transfer(src, dst, sad);
        return true;
    }

    function increaseAllowance(address guy, uint256 addedValue) public returns (bool) {
        require(guy != address(0));

        allowance_[msg.sender][guy] = allowance_[msg.sender][guy].add(addedValue, "allowance addition overflow") ;
        emit Approval(msg.sender, guy, allowance_[msg.sender][guy]);
        return true;
    }

    function decreaseAllowance(address guy, uint256 subtractedValue) public returns (bool) {
        require(guy != address(0));

        allowance_[msg.sender][guy] = allowance_[msg.sender][guy].sub(subtractedValue, "allowance subtraction overflow") ;
        emit Approval(msg.sender, guy, allowance_[msg.sender][guy]);
        return true;
    }
}