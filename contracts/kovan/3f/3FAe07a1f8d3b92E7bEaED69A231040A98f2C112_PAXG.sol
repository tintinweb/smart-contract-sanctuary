/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// hevm: flattened sources of src/tokens/PAXG.sol
pragma solidity >=0.5.12;

////// src/tokens/PAXG.sol
/* pragma solidity >=0.5.12; */

contract PAXG {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
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
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    
    event FeeCollected(address indexed from, address indexed to, uint256 value);
    event FeeRateSet(
        uint256 indexed oldFeeRate,
        uint256 indexed newFeeRate
    );

    string  public  name = "Paxos Gold";
    string  public  symbol = "PAXG";
    uint256 public  decimals = 18;
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    uint256 public constant feeParts = 1000000;
    uint256 public feeRate;
    address public feeRecipient = 0x57aAeAE905376a4B1899bA81364b4cE2519CBfB3;       // Doesn't really matter where the fees go (send to faucet)

    constructor(uint256 supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            require(_approvals[src][msg.sender] >= wad, "insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "insufficient-balance");
        uint256 _fee = getFeeFor(wad);
        uint256 _principal = sub(wad, _fee);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], _principal);

        emit Transfer(src, dst, _principal);
        emit Transfer(src, feeRecipient, _fee);

        if (_fee > 0) {
            _balances[feeRecipient] = add(_balances[feeRecipient], _fee);
            emit FeeCollected(src, feeRecipient, _fee);
        }

        return true;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function setFeeRate(uint256 _newFeeRate) public {
        require(_newFeeRate <= feeParts, "cannot set fee rate above 100%");
        uint256 _oldFeeRate = feeRate;
        feeRate = _newFeeRate;
        emit FeeRateSet(_oldFeeRate, feeRate);
    }

    function getFeeFor(uint256 _value) public view returns (uint256) {
        if (feeRate == 0) {
            return 0;
        }

        return div(mul(_value, feeRate), feeParts);
    }

}