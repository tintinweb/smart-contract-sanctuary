pragma solidity ^0.4.21;

// It makes multiple ERC20 (even ERC223) transaction in one.
// Need to deposit before spread
// Transfer to this contract is available as deposit
contract Airdroper {
    mapping (address => mapping (address => uint)) balances;

    constructor() public {}

    function subtr(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function addit(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function tokenFallback(address _from, uint _amount, bytes _data) public returns (bool) {
        balances[msg.sender][_from] = addit(balances[msg.sender][_from], _amount);
        if (_data.length != 0) {
            require(address(this).call(_data));
        }
        return true;
    }

    function deposit(address _token, uint _amount) public returns (bool) {
        // 0x23b872dd is function signature of `transferFrom(address,address,uint256)`
        require(_token.call(0x23b872dd, msg.sender, this, _amount));
        balances[_token][msg.sender] = addit(balances[_token][msg.sender], _amount);
        return true;
    }

    function balanceOf(address _token, address _user) public view returns (uint) {
        return balances[_token][_user];
    }

    function spread(address _token, address[] _addresses, uint[] _amounts) public returns (bool) {
        uint l = _addresses.length;
        for (uint i = 0; i < l; i++) {
            require(balances[_token][tx.origin] >= _amounts[i]);
            // 0xa9059cbb is function signature of `transfer(address,uint256)`
            require(_token.call(0xa9059cbb, _addresses[i], _amounts[i]));
            balances[_token][tx.origin] = subtr(balances[_token][tx.origin], _amounts[i]);
        }
        return true;
    }
}