/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity >=0.4.25 <0.6.0;

contract DigitalLocker
{
    enum StateType { Requested, DocumentReview, AvailableToShare, SharingRequestPending, SharingWithThirdParty, Terminated }
    StateType public State;
    
    address public Owner;
    address public BankAgent;
    address public ThirdPartyRequestor;
    address public CurrentAuthorizedUser;
    
    string public LockerFriendlyName;
    string public LockerIdentifier;
    string public ExpirationDate;
    string public Image;
    string public IntendedPurpose;
    string public LockerStatus;
    string public RejectionReason;
    

    constructor(string memory lockerFriendlyName, address bankAgent) public
    {
        Owner = msg.sender;
        LockerFriendlyName = lockerFriendlyName;

        State = StateType.DocumentReview; //////////////// should be StateType.Requested?

        BankAgent = bankAgent;
    }

    function BeginReviewProcess() public
    {
        /* Need to update, likely with registry to confirm sender is agent
        Also need to add a function to re-assign the agent.
        */

        BankAgent = msg.sender;

        LockerStatus = "Pending";
        State = StateType.DocumentReview;
    }

    function RejectApplication(string memory rejectionReason) public
    {

        RejectionReason = rejectionReason;
        LockerStatus = "Rejected";
        State = StateType.DocumentReview;
    }

    function UploadDocuments(string memory lockerIdentifier, string memory image) public
    {

        LockerStatus = "Approved";
        Image = image;
        LockerIdentifier = lockerIdentifier;
        State = StateType.AvailableToShare;
    }

    function ShareWithThirdParty(address thirdPartyRequestor, string memory expirationDate, string memory intendedPurpose) public
    {

        ThirdPartyRequestor = thirdPartyRequestor;
        CurrentAuthorizedUser = ThirdPartyRequestor;

        LockerStatus = "Shared";
        IntendedPurpose = intendedPurpose;
        ExpirationDate = expirationDate;
        State = StateType.SharingWithThirdParty;
    }

    function AcceptSharingRequest() public
    {
  
        CurrentAuthorizedUser = ThirdPartyRequestor;
        State = StateType.SharingWithThirdParty;
    }

    function RejectSharingRequest() public
    {
        LockerStatus = "Available";
        CurrentAuthorizedUser = 0x0000000000000000000000000000000000000000;
        State = StateType.AvailableToShare;
    }

    function RequestLockerAccess(string memory intendedPurpose) public
    {

        ThirdPartyRequestor = msg.sender;
        IntendedPurpose = intendedPurpose;
        State = StateType.SharingRequestPending;
    }

    function ReleaseLockerAccess() public
    {

        LockerStatus = "Available";
        ThirdPartyRequestor = 0x0000000000000000000000000000000000000000;
        CurrentAuthorizedUser = 0x0000000000000000000000000000000000000000;
        IntendedPurpose = "";
        State = StateType.AvailableToShare;
    }
    
    function RevokeAccessFromThirdParty() public
    {

        LockerStatus = "Available";
        CurrentAuthorizedUser = 0x0000000000000000000000000000000000000000;
        State = StateType.AvailableToShare;
    }

    function Terminate() public
    {

        CurrentAuthorizedUser = 0x0000000000000000000000000000000000000000;
        State = StateType.Terminated;
    }
}