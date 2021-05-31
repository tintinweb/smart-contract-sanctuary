pragma solidity 0.8.4;

interface IAkuToken {
    function mint(address to, uint amount) external;
    function burnFrom(address account, uint amount) external;
}

contract Issuance {
    IAkuToken private _akuToken;
    address public issuer;
    
    event Deposit(address indexed user, uint amount);
    event Withdrawal(address indexed user, uint amount);

    constructor(address akuToken, address _issuer) {
        _akuToken = IAkuToken(akuToken);
        issuer = _issuer;
    }

    modifier onlyIssuer() {
        require(msg.sender == issuer, "ISSUER: only issuer can do this");
        _;
    }

    function deposit(address user, uint amount) external onlyIssuer() {
        _akuToken.mint(user, amount);
        emit Deposit(user, amount);
    }

    function withdraw(address user, uint amount) external onlyIssuer() {
        _akuToken.burnFrom(user, amount);
        emit Withdrawal(user, amount);
    }

    function token() external view returns(address complianceToken) {
        return address(_akuToken);
    }
    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}