pragma solidity ^0.5.0;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract Factory {
    function generate(address _owner, address _admin) public returns(address) {
        require(_owner != address(0) && address(this) != _owner);
        require(_admin != address(0) && address(this) != _admin);
        return address(new HotWallet(_owner, _admin));
    }
}
contract HotWallet {
    address owner;
    address admin;
    constructor(address _owner, address _admin) public {
        owner = _owner;
        admin = _admin;
    }
    modifier restrict() {
        if (msg.sender != owner && msg.sender != admin)
        revert();
        _;
    }
    function addressOk(address _account) internal view returns(bool) {
        if (_account != address(0) && address(this) != _account) return true;
        else return false;
    }
    function setting(address _owner, address _admin) public restrict returns(bool) {
        require(addressOk(_owner) && addressOk(_admin));
        owner = _owner;
        admin = _admin;
        return true;
    }
    function() external payable {}
    function callContract(address _address, uint256 _amount, uint256 _gas, bytes memory _data) public restrict returns(bool, bytes memory) {
        require(addressOk(_address) && _amount <= address(this).balance);
        if (_gas < 25000) _gas = 50000;
        (bool success, bytes memory responseData) = address(uint160(_address)).call.gas(_gas).value(_amount)(_data);
        if (!success) revert();
        return (success, responseData);
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function send(address _recipient, uint256 _amount) public restrict returns(bool) {
        require(addressOk(_recipient));
        require(_amount > 0 && _amount <= address(this).balance);
        address(uint160(_recipient)).transfer(_amount);
        return true;
    }
    function transfer(address _token, address _recipient, uint256 _amount) public restrict returns(bool) {
        require(addressOk(_recipient) && address(0) != _token);
        require(_amount > 0 && _amount <= ERC20(_token).balanceOf(address(this)));
        if (!ERC20(_token).transfer(_recipient, _amount)) revert();
        return true;
    }
}