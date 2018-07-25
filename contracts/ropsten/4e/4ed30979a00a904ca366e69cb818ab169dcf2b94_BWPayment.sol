pragma solidity ^0.4.21;

contract ERC20Basic {
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);

    function transfer(address _to, uint _tokens) public returns (bool);
    function transferFrom(address _from, address _to, uint _tokens) public returns (bool);

    function allowance(address _owner, address _spender) public view returns (uint);
    function approve(address _spender, uint _tokens) public returns (bool);
}

contract BWPayment {

    address private owner;
    address private token;

    /* Defined Event */
    
    event Transferred(address indexed previousAddress, address indexed newAddress);

    /* Defined Modifier */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   

    constructor (address _owner, address _token) public {
        require(_owner != address(0) && _token != address(0));

        owner = _owner;
        token = _token;
    }

    function () public payable {
        revert();
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0));

        owner = _owner;
        emit Transferred(owner, _owner);
    }

    function transferTokenAddress(address _token) external onlyOwner {
        require(_token != address(0));

        token = _token;
        emit Transferred(token, _token);
    }

    function pay(address consumer, uint256 amount) external onlyOwner returns (bool) {        
        ERC20Basic tokenContract = ERC20Basic(token);        
        return tokenContract.transferFrom(consumer, this, amount);
    }

    function sendReward(address rewardWallet, address promoter, uint256 amount) external onlyOwner returns (bool) {        
        ERC20Basic tokenContract = ERC20Basic(token);
        return tokenContract.transferFrom(rewardWallet, promoter, amount);
    }

    function confirm(address host, uint256 amount) external onlyOwner returns (bool) {        
        ERC20Basic tokenContract = ERC20Basic(token);        
        return tokenContract.transfer(host, amount);
    }
}