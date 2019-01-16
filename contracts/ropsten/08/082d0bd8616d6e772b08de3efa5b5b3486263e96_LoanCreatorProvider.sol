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