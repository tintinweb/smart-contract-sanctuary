// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
import "./Safemath.sol";

contract PeachStorage {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private locked;

    address manager = 0x2DEbCd8eCD0aecd3234c92eaA8B4Eb7421b7aBe6;
    address owner = 0x2DEbCd8eCD0aecd3234c92eaA8B4Eb7421b7aBe6;
    address ecosystem = 0x197b53e2ea9500ecFC0D6E34F061174eB1D9a9bc;
    address ido = 0x95D770074A03f1B8D32Eb598AcA08C07A1998982;
    address publicPresale = 0x804a3B14730462c7FFB70E5BCB1368c7adcE5775;
    address rewardPool = address(0);
    address team = address(0);
    address dex = address(0);
    address marketing = address(0);
    address staking = address(0);
    address advisor = address(0);
    address airdrop = address(0);
    address charity = address(0);
    address privateSale = address(0);

    string _name = "Darling Waifu Peach Storage";
    string _symbol = "PSTR";
    uint8 _decimals = 18;
    uint256 _totalSupply = 5000000 * 10**_decimals;

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        balances[owner] = _totalSupply / 100;
        balances[ecosystem] = 500000 * 10**_decimals;
        balances[ido] = 400000 * 10**_decimals;
        balances[publicPresale] = 100000 * 10**_decimals;
        balances[rewardPool] = 2300000 * 10**_decimals;
        balances[team] = 500000 * 10**_decimals;
        balances[dex]  = 400000 * 10**_decimals;
        balances[marketing] = 200000 * 10**_decimals;
        balances[staking] = 200000 * 10**_decimals;
        balances[advisor] = 150000 * 10**_decimals;
        balances[airdrop] = 100000 * 10**_decimals;
        balances[charity] = 50000 * 10**_decimals;
        balances[privateSale] = 100000 * 10**_decimals;
    }

    // Token information functions
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function upgradePeach(address _newPeach) external onlyOwner {
        manager = _newPeach;
    }

    function getPeach() external view returns (address) {
        return manager;
    }

    function balanceOf(address _wallet) external view returns (uint256) {
        return balances[_wallet];
    }

    event Transfer(address from, address to, uint256 ammount);

    function transfer(
        address _from,
        address _to,
        uint256 _ammount
    ) external onlyManager {
        require(balances[_from] >= _ammount);
        balances[_from] = balances[_from].sub(_ammount);
        balances[_to] = balances[_to].add(_ammount);
        emit Transfer(_from, _to, _ammount);
    }

    function claim(address _target, uint256 _ammount) external onlyManager {
        require(locked[_target] >= _ammount);
        locked[_target] = locked[_target].sub(_ammount);
        balances[_target] = balances[_target].add(_ammount);
        emit Transfer(address(0), _target, _ammount);
    }
}