contract DelegateProxy {
  /**
   * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
   * @param _dst Destination address to perform the delegatecall
   * @param _calldata Calldata for the delegatecall
   */
  function delegatedFwd(address _dst, bytes _calldata) internal {
    assembly {
      let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

      // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
      // if the call returned error data, forward it
      switch result case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

contract Token {
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function approve(address _spender, uint256 _value) returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
}

contract DelegateProvider {
    function getDelegate() public view returns (address delegate);
}

contract WalletStorage {
    address public owner;
}

contract WalletProxy is WalletStorage, DelegateProxy {
    event ReceivedETH(address from, uint256 amount);

    constructor() public {
        owner = msg.sender;
    }

    function() public payable {
        if (msg.value > 0) {
            emit ReceivedETH(msg.sender, msg.value);
        }
        if (gasleft() > 2400) {
            delegatedFwd(DelegateProvider(owner).getDelegate(), msg.data);
        }
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.
        @param _to Address of the new owner
    */
    function setOwner(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
} 

contract LoanCreatorProvider is Ownable {
    address public loanCreator;

    event ChangedLoanCreator(address _prevLoanCreator, address _loanCreator);

    function setLoanCreator(address _loanCreator) external onlyOwner {
        emit ChangedLoanCreator(loanCreator, _loanCreator);
        loanCreator = _loanCreator;
    }
    
    function loanCreator() external view returns (address) {
        return loanCreator;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract LoanApprover is IERC165 {
    function approveRequest(bytes32 _futureDebt) external returns (bytes32);
    function settleApproveRequest(bytes _requestData, bytes _loanData, bool _isBorrower, uint256 _id) external returns (bytes32);
}

contract LoanManager {
    function getCreator(uint256 _id) external view returns (address);
}

contract Wallet2 is WalletStorage, LoanApprover {
    function transferERC20Token(Token token, address to, uint256 amount) public returns (bool) {
        require(msg.sender == owner);
        return token.transfer(to, amount);
    }
    
    function transferEther(address to, uint256 amount) public returns (bool) {
        require(msg.sender == owner);
        return to.call.value(amount)();
    }
    
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return (
            interfaceID == 0x01ffc9a7 ||
            interfaceID == 0x76ba6009 ||
            interfaceID == 0xbbfa4397
        );
    }

    function approveRequest(bytes32 _id) external returns (bytes32) {
        require(
            LoanCreatorProvider( // Avoid using storage
                0x082D0BD8616d6e772B08dE3efa5B5B3486263E96
            ).loanCreator() == LoanManager(msg.sender).getCreator(uint256(_id)),
            "An authorized creator did not create the loan"
        );
        return _id ^ 0xdfcb15a077f54a681c23131eacdfd6e12b5e099685b492d382c3fd8bfc1e9a2a;
    }

    function settleApproveRequest(bytes,bytes,bool,uint256) external returns (bytes32) {
        revert(&#39;Not implemented&#39;);
    }

    function() public payable {}
}