import "./wXEQ.sol";

contract equilibria_bridge is Ownable  {
    
    using SafeMath for *;

    IERC20 public wXEQContract;

    mapping(string => bool) public xeq_complete;
    mapping(string => uint256) public xeq_amounts;
    mapping(string => address) public eth_addresses;

    uint256 public to_volume;
    uint256 public from_volume;
    uint256 devFeePercent;

    event to_eon(string indexed _to, uint256 _value);
    event from_eon(address indexed _to, string indexed _txid, uint256 _value);
    event admin_transfer(address indexed _to, uint256 _value);

    constructor(address _wxeq)  {
        wXEQContract = IERC20(_wxeq);
        transferOwnership(msg.sender);
        devFeePercent = 2500;
    }
    
    function devFee(uint256 _value, uint256 devFeeVal1) public pure returns (uint256) {
        return ((_value.mul(devFeeVal1)).div(10000));
    }
    
    function devFee(uint _value) public view returns (uint256) {
        return ((_value.mul(devFeePercent)).div(10000));
    }
    
    function setDevFee(uint256 val) public onlyOwner returns (bool) {
        devFeePercent = val;
        assert(devFeePercent == val);
        return true;
    }
    
    function request_to_xeq(uint256 _amount, string memory _to) public {
        require(wXEQContract.balanceOf(msg.sender) >= _amount);
        require(wXEQContract.allowance(msg.sender, address(this)) >= _amount);

        wXEQContract.transferFrom(msg.sender, address(this), _amount);
        to_volume = to_volume.add(_amount);
        uint256 fee = devFee(_amount, devFeePercent);
        wXEQContract.transfer(owner(), fee);
        emit to_eon(_to, _amount.sub(fee));
    }
    
    function claim_from_xeq(string memory tx_hash) public {
        require(xeq_amounts[tx_hash] != 0);
        require(!xeq_complete[tx_hash]);
        require(eth_addresses[tx_hash] == msg.sender);
        xeq_complete[tx_hash] = true;
        uint256 fee = devFee(xeq_amounts[tx_hash], devFeePercent);
        wXEQContract.transfer(owner(), fee);
        wXEQContract.transfer(eth_addresses[tx_hash], xeq_amounts[tx_hash].sub(fee));
        from_volume = from_volume.add(xeq_amounts[tx_hash]);
        emit from_eon(eth_addresses[tx_hash], tx_hash, xeq_amounts[tx_hash]);
    }
    
    function register(address account, string memory tx_hash, uint256 amount) public onlyOwner returns (bool) {
        require(!xeq_complete[tx_hash]);
        require(xeq_amounts[tx_hash] == 0);
        require(eth_addresses[tx_hash] == address(0));
        eth_addresses[tx_hash] = account;
        xeq_amounts[tx_hash] = amount;
        return true;
    }
    
    function isSwapRegistered(string memory tx_hash) public view returns (bool) {
        if(xeq_amounts[tx_hash] == 0) 
        {
            return false;
        }
        return true;
    }
    
    function adminTransfer(uint256 _amount, address _addy ) public onlyOwner {
        require(_addy != address(0));
        wXEQContract.transfer(_addy, _amount);
        emit admin_transfer(_addy, _amount);
    }
    
    
}