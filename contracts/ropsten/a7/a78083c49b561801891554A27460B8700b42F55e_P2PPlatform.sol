/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

// SPDX-License-Identifier: DEFI

pragma solidity 0.7.0; // Solidity compiler version

// *********************** Interfaces - Starts ************************* //

interface RequestFactoryInterface {
    function createLendingRequest(uint256, uint256, string calldata, address payable, address payable, uint256, uint256) external payable returns(address payable);
}

interface LendingRequestInterface {
    function lend(address payable) external returns(bool);
    function payback(address payable) external returns(bool);
    function collectCollateral(address) external returns(bool);
    function cancelRequest(address) external returns(bool);
    function getRequestParameters() external view returns(address payable, address payable, uint256, uint256, string memory);
    function getRequestState() external view returns(bool, bool, uint256, bool, uint256, uint256);
}

// *********************** Interfaces - Ends ************************* //

// *********************** P2PLendingAndBorrowing - Starts ************************* //

contract P2PPlatform {

    // Events
    event RequestCreated();
    event RequestGranted();
    event DebtPaid();
    event Withdraw();

    // State mapping
    mapping(address => uint256) private requestIndex;
    mapping(address => uint256) private userRequestCount;
    mapping(address => bool) private validRequest;

    // State Variables
    address private requestFactory;
    address[] private lendingRequests;

    constructor(address _factory) {
        requestFactory = _factory;
    }

    /**
     * @notice Creates a lending request for the amount you specified
     * @param _amount the amount you want to borrow in Wei
     * @param _paybackAmount the amount you are willing to pay back - has to be greater than _amount
     * @param _purpose the reason you want to borrow ether
     */
    function ask(uint256 _amount, uint256 _paybackAmount, string memory _purpose, address payable _token, uint256 _collateralCollectionTimeStamp) public payable returns(bool success){

        // validate the input parameters
        require(_amount > 0, "Amount should be greater than 0");
        require(_paybackAmount > _amount, "Payback amount should be greater than payback");

        // Check if collateral is given
        require(msg.value > 0, "some collateral should be given");

        // Create New lendingRequest
        address payable request = RequestFactoryInterface(requestFactory).createLendingRequest{value :msg.value}(
            _amount,
            _paybackAmount,
            _purpose,
            msg.sender,
            _token,
            msg.value,
            _collateralCollectionTimeStamp
        );

        // update number of requests for asker
        userRequestCount[msg.sender]++;

        // add created lendingRequest to management structures
        requestIndex[request] = lendingRequests.length;
        lendingRequests.push(request);

        // mark created lendingRequest as a valid request
        validRequest[request] = true;

        emit RequestCreated();

        return true;
    }

    /**
     * @notice Lend ether amount of the lendingRequest (costs ETHER)
     * @param _lendingRequest the address of the lendingRequest you want to deposit ether in
     */
    function lend(address payable _lendingRequest) public {

        // Validate Request
        require(validRequest[_lendingRequest], "Invalid Request");

        bool success = LendingRequestInterface(_lendingRequest).lend(msg.sender);
        require(success, "Lending failed");

        // Emit Event
        emit RequestGranted();

    }

    /**
     * @notice payback the ether amount of the lendingRequest (costs ETHER)
     * @param _lendingRequest the address of the lendingRequest you want to deposit ether in
     */
    function payback(address payable _lendingRequest) public {

        // Checks
        require(validRequest[_lendingRequest], "Invalid Request");

        bool success = LendingRequestInterface(_lendingRequest).payback(msg.sender);
        require(success, "Payback failed");

        // Emit Event
        emit RequestGranted();

    }


    function collectColletral(address payable _lendingRequest) public {

        // Checks
        require(validRequest[_lendingRequest], "Invalid Request");

        bool success = LendingRequestInterface(_lendingRequest).collectCollateral(msg.sender);
        require(success, "collectCollateral failed");

        // Emit Event
        emit RequestGranted();

    }

    /**
     * @notice cancels the request
     * @param _lendingRequest the address of the request to cancel
     */
    function cancelRequest(address payable _lendingRequest) public {

        // validate input
        require(validRequest[_lendingRequest], "Invalid Request");

        bool success = LendingRequestInterface(_lendingRequest).cancelRequest(msg.sender);
        require(success, "cancelRequest failed");

        // Remove Request
        removeRequest(_lendingRequest, msg.sender);

        emit RequestGranted();
    }

    /**
     * @notice removes the lendingRequest from the management structures
     * @param _request the lendingRequest that will be removed
     */
    function removeRequest(address _request, address _sender) private {

        // validate input
        require(validRequest[_request], "Invalid Request");

        // update number of requests for asker
        userRequestCount[_sender]--;

        // remove _request from the management contract
        uint256 idx = requestIndex[_request];
        if(lendingRequests[idx] == _request) {
            requestIndex[lendingRequests[lendingRequests.length - 1]] = idx;
            lendingRequests[idx] = lendingRequests[lendingRequests.length - 1];
            lendingRequests.pop();
        }
        // mark _request as invalid lendingRequest
        validRequest[_request] = false;
    }


    function getRequestParameters(address payable _lendingRequest)
        public
        view
        returns (address asker, address lender, uint256 askAmount, uint256 paybackAmount,string memory purpose) {
        (asker, lender, askAmount, paybackAmount, purpose) = LendingRequestInterface(_lendingRequest).getRequestParameters();
    }

    function getRequestState(address payable _lendingRequest)
        public
        view
        returns (bool moneyLent, bool debtSettled, uint256 collateral, bool collateralCollected, uint256 collateralCollectionTimeStamp, uint256 currentTimeStamp) {
        return LendingRequestInterface(_lendingRequest).getRequestState();
    }

    function getColletralBalance(address _lendingRequest) public view returns(uint256){
        return address(_lendingRequest).balance;
    }

    /**
     * @notice gets the lendingRequests for the specified user
     * @return all lendingRequests
     */
    function getRequests() public view returns(address[] memory) {
        return lendingRequests;
    }


}

// *********************** P2PLendingAndBorrowing - Ends ************************* //