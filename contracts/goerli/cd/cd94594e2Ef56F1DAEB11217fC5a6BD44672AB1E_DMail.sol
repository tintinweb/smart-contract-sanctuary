//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

contract DMail {
    mapping(address => string) public keyPair;

    struct Message {
        address from;
        address to;
        string content;
        address token;
        uint256 amount;
    }

    mapping(uint256 => Message) public messages;

    uint256 public index;

    address public governance;
    address public pendingGovernance;

    event Sent(address _from, address _to, address _token, uint256 _amount);
    event KeyPair(address _user, string _keyPair);

    modifier onlyGovernance() {
        require(msg.sender == governance, 'NA');
        _;
    }

    constructor(address _governance) {
        governance = _governance;
    }

    /**
     * @notice Adds new private and public key pair IPFS hash
     * @param _keyPair IPFS hash of the _keyPair
     */
    function addKeyPair(string memory _keyPair) external {
        keyPair[msg.sender] = _keyPair;
        emit KeyPair(msg.sender, _keyPair);
    }

    /**
     * @notice Sends emails
     * @param _to Where should the email go
     * @param _content content of the message
     * @param _token Address of the token
     * @param _amount Amount to attach
     */
    function send(
        address _to,
        string memory _content,
        address _token,
        uint256 _amount
    ) external {
        Message storage message = messages[index + 1];
        message.from = msg.sender;
        message.to = _to;
        message.amount = _amount;
        message.content = _content;
        index = index + 1;
        emit Sent(msg.sender, _to, _token, _amount);
    }

    /**
     * @notice Initiates two step governance change process
     * @param _governance Address of the new governance
     */
    function changeGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    /**
     * @notice Accept governance, should be called from pending governance
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "metadata": {
    "bytecodeHash": "none"
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}