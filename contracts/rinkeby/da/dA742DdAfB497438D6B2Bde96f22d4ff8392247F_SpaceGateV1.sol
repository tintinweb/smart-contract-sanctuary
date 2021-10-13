/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;


library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

abstract contract Ownable {
    address payable public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 {
    uint public _totalSupply;
    function  totalSupply() public virtual view returns (uint);
    function balanceOf(address who) public virtual view returns (uint);
    function transfer(address to, uint value) public virtual;
    function allowance(address owner, address spender) public virtual view returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
}

contract SpaceGateV1 is Ownable{
    bool isPause;
    using SafeMath for uint256;
    
    // Statistical tracking user information 
    struct UserInfo {
        uint256 total;
        uint256 totalFee;
        uint256 amount;
    }
    
    // Gate swap token
    struct GateInfo {
        bool flag; // Flag for check existed
        uint256 min; // Min amount one time
        uint256 max; // Max amount one time
        string gate; // Gate id
        address contractToken; // Contract token address
        uint256 claimFee; // Fee claimed for gate
        uint256 fee; // Fee system
        uint256 totalClaim; // Total Fee Claim
        uint256 totalFee; // Total Fee system
    }
    
    mapping(address => UserInfo) public UserInfos;
    mapping(string => GateInfo) public Gates;
    
    // event emit when gate token
    event gate(
        address sender,
        uint256 receivedAmount,
        string gate
    );
    
    // validate gate
    function validGate(string memory _gate) internal view returns (bool isValid){
        return Gates[_gate].flag ;
    }

    // configure fee for existed gate (*)
    function configureFee(
        string memory _gate,
        uint256 _fee,
        uint256 _claimFee
    )
        public
        onlyOwner()
    {
        require(validGate(_gate), "Gate not found");
        
        Gates[_gate].fee = _fee;
        Gates[_gate].claimFee = _claimFee;
    }
    
    // configure min max for existed gate (*)
    function configureMinMax(
        string memory _gate,
        uint256 _min,
        uint256 _max
    )
        public
        onlyOwner()
    {
        require(validGate(_gate), "Gate not found");
        
        Gates[_gate].min = _min;
        Gates[_gate].max = _max;
    }
    
    // delete existed gate (*)
    function unRegister(
        string memory _gate
    )
        public
        onlyOwner()
    {
        require(validGate(_gate), "Gate not found");
        delete Gates[_gate];
    }

    // import new gate (*)
    function register(
        string memory _gate,
        uint256 _min,
        uint256 _max,
        uint256 _fee,
        uint256 _claimFee
    )
        public
        onlyOwner()
    {
        require(!validGate(_gate), "Gate already existed");
        Gates[_gate].min = _min;
        Gates[_gate].max = _max;
        Gates[_gate].fee = _fee;
        Gates[_gate].claimFee = _claimFee;
    }

    function spaceGate(
        uint256 _amount,
        string memory _gate
    )
        external
        payable
    {
        require(!isPause);
        require(validGate(_gate), "Gate not found");
        GateInfo memory gateInfo = Gates[_gate];
        
        address _contractToken = gateInfo.contractToken;
        
        require(msg.value != 0 || _contractToken != address(0), "Amount Incorrect");
        // check user sends ETH or ERC20
        if (msg.value != 0) {
            // override the _amount and token address
            _amount = msg.value;
            _contractToken = address(0);
        }
        
        require(gateInfo.min<=_amount && gateInfo.max>=_amount);

        if (_contractToken != address(0)) {
            ERC20(_contractToken).transferFrom(msg.sender, address(this), _amount);
        }
    
        uint256 claimFee = _amount.mul(Gates[_gate].claimFee); 
        uint256 fee = _amount.mul(Gates[_gate].fee); 
        
        gateInfo.totalClaim = gateInfo.totalClaim.add(claimFee);
        gateInfo.totalFee = gateInfo.totalFee.add(fee);

        UserInfo memory user = UserInfos[msg.sender];
        user.total = user.total.add(1);
        user.totalFee = user.total.add(claimFee).add(fee);
        user.amount = user.amount.add(_amount);

        emit gate(
            msg.sender,
            _amount,
            _gate
        );
    }
    
    // Gate withdraw
    function withdraw(uint256 _amount, string memory _gate) public onlyOwner {
        require(validGate(_gate), "Gate not found");
        require(_amount > 0);
        
        GateInfo memory gateInfo = Gates[_gate];
        address _contractToken = gateInfo.contractToken;
        
        if(_contractToken == address(0)){
          owner.transfer(_amount);
        } else {
          ERC20 coin = ERC20(gateInfo.contractToken);
          require(coin.balanceOf(address(this)) >= _amount);
          coin.transfer(owner, _amount);
        }
    }

    function pause() external onlyOwner() {
       isPause = true;
    }

    function unpause() external onlyOwner() {
      isPause= false;
    }
}