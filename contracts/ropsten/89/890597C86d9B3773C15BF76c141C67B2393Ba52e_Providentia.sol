pragma solidity ^0.5.0;

import "./ERC1155MixedFungibleMintable.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./TimeHelper.sol";
import "./SafeMath.sol";

/**
    @title Providentia, providing students with loan
    @dev See https://providentia.netlify.com/
    Note: Some values are hardcoded in order to represent a specific usecase
 */

contract Providentia is Ownable, ERC20, ERC1155MixedFungibleMintable{
  // @dev Library used to calculate time differences
  using BokkyPooBahsDateTimeLibrary for uint;
  // @dev Library to prevent integer overflow/underflow
  using SafeMath for uint;

    // @dev Mapping used to store user data
    mapping( address => StudentData ) public addressToData;
    // @dev Mapping used to store the details of the Loan
    mapping( address => StudentLoan) public addressToLoan;
    // @dev Mapping used to track the Loan of the student
    mapping( address => uint) public addressToBalance;
    // @dev Mapping used to track the interest paid by the student
    mapping( address => uint) public studentToInterest;
    // @dev Mapping to know if the user has an outstanding loan
    mapping( address => bool ) studentHasLoan;
    // @dev address =>( idNFT => idFT )
    mapping( address => mapping( uint => uint)) ownerToTypes;
    // idNFT => amountTokens
    // note: One NFT MUST have 100 FT attached, no more no less
    mapping( address => mapping(uint => uint) ) tokensToValue;
    // @dev Name of University To Address
    mapping( string => address) addressToUniversity;
    // @dev Address to amount of repaid loan
    mapping( address => uint) addressToRepaid;
    // @dev Address to amount remaining to investor( used to track withdrawals of investors)
    mapping( address => uint) addressToInvestor;

        /***********************************|
        |        Variables and Events       |
        |__________________________________*/

    event studentCreated (
        address addressStudent,
        uint studentId,
        string _name,
        uint _age,
        string _country,
        string _profAccount,
        string _university
        );

    struct StudentData {
        address addressStudent;
        uint studentId;
        string name;
        uint age;
        string country;
        string university;
        string profAccount;
        uint idNFT;
    }

    struct StudentLoan {
        uint amountDAI;
        uint interestLoan;
        uint amountFunded;
        uint startDate;
        uint endDate;
        bool loanFunded;
        bool loanAccepted;
        bool loanRepaid;
    }

    struct FunderTokens {
      address _addressFunder;
      uint _amount;
      address _addressFunded;
      uint idNFT;
    }

    FunderTokens[] public Investors;

    StudentData[] public Students;

    address[] sendTokens ;

    uint[] valueSend = [100];

    address stableCoinAddress ;

    ERC1155MixedFungibleMintable _token;

    modifier hasRequestedLoan(){
      // Check if Student has already requested a loan
        require( addressToLoan[msg.sender].amountDAI == 0, "User has already initiated a Loan process");
        _;
    }

    modifier hasFundedLoan(address _addressToFund){
      require( addressToLoan[_addressToFund].loanFunded == false && addressToLoan[_addressToFund].endDate != 0
        , "User has already a funded loan");
      _;
    }

    modifier hasActiveLoan(){
      require(studentHasLoan[msg.sender] == true, "This address doesn&#39;t have a loan associated");
      _;
    }

    modifier onlySchool(address _addressFunded){
      require( addressToUniversity[addressToData[_addressFunded].university] == msg.sender,
        "The sender is not an approved school");
        _;
    }

    constructor(address _stableCoinAddress, ERC1155MixedFungibleMintable _tokenIERC1155) public{
        stableCoinAddress = _stableCoinAddress;
        _token = _tokenIERC1155;
        sendTokens.push(msg.sender);
    }

    /**
      @notice Function used to upgrade the contract address of DAI in case it changes
      @param _addressCoin Address of the StableCoin Contract
    */
    function setStableCoinAddress(address _addressCoin) public onlyOwner{
        stableCoinAddress = _addressCoin;
    }

    /**
      @notice Function used to add the Student
      @param _addressStudent Address of the Student to add
      @param _studentId Id of the student
      @param _name Name of the Student
      @param _age Age of the Student
      @param _country Country of the Student
      @param _profAccount Github account of the Student
      @param _university University in which the Student is attending to
      @param _uri Used to store the JSON with the data of the Student
    */
    function addStudent(
      address _addressStudent,
      uint _studentId,
      string memory _name,
      uint _age,
      string memory _country,
      string memory _profAccount,
      string memory _university,
      string memory _uri
    )
      public

    {

        require(bytes(addressToData[_addressStudent].name).length == 0,
        "An address can only have one Student associated");

        require(addressToUniversity[_university] != address(0), "University hasn&#39;t been added yet");

        require(msg.sender == addressToUniversity[_university], "Sender is not a registered university");

        // Mint NFT
        uint _type = _token.create(_uri, true);
        // Send tokens to owner
        _token.mintNonFungible(_type, sendTokens);
        // Mint FT
        uint _id = _token.create(_uri, false);
        // Send tokens to owner
        _token.mintFungible(_id, sendTokens, valueSend );

        //Updae the mapping
        addressToData[_addressStudent] = StudentData(
          _addressStudent,
          _studentId,
          _name,
          _age,
          _country,
          _university,
          _profAccount,
          _type
          );

        Students.push(StudentData(
          _addressStudent,
          _studentId,
          _name,
          _age,
          _country,
          _university,
          _profAccount,
          _type));

          // Trigger event
        emit studentCreated(
          _addressStudent,
          _studentId,
          _name,
          _age,
          _country,
          _profAccount,
          _university
          );
    }

    /**
      @notice Function used to add the school, only the owner can add school, to prevent misbehavior
      @param _addressSchool Ethereum address of the school
      @param _universityName Name of the university to add
    */
    function addSchool(
      address _addressSchool,
      string memory _universityName
      )
      public onlyOwner{
        require(addressToUniversity[_universityName] == address(0), "University already registered");
        // Set address of the school
        addressToUniversity[_universityName] = _addressSchool;
    }

    /**
      @notice Function used to initiate a Loan process and get funded
      @param _interestLoan Interest rate the student is willing to pay
      @dev For this usecase the Student can request a fixed amount of 10000 DAI
           and have a deadline of 5 years to repay the Loan
    */
    function requestLoan( uint _interestLoan) public hasRequestedLoan{

        //Check if the Student has been added before letting him request a loan
        require(bytes(addressToData[msg.sender].name).length != 0,
        "Student hasn&#39;t been added yet");
        /*  This version will use a fixed value of 50k for the amount of loan to
            request, the loan has a deadline of 5 years */
        addressToLoan[msg.sender] = StudentLoan(10000, _interestLoan, 0, now, now.addYears(5), false, false, false);
        // Instantiate the mapping to 0
        addressToBalance[msg.sender] = 0;
        // When requesting a loan, the School hasn&#39;t accept it yet
        studentHasLoan[msg.sender] = false;
        // Instantiate the mapping
        addressToRepaid[msg.sender] = 0;
        //Instantiate the Mapping
        addressToInvestor[msg.sender] = 0;

    }

    /**
      @notice Function used to add money to the pool for the Student
      @param _addressToFund Address of the user to be funded
      @dev Each token costs 100 DAI and each token represents a share of the loan

    */
    function addMoneyPool(address _addressToFund) public hasFundedLoan(_addressToFund){


      require(_addressToFund != address(0), "Address 0 given");
      ERC20 stableCoinContract = ERC20(stableCoinAddress);
      // Check the allowance given to the contract
      uint tokenAmount = stableCoinContract.allowance(msg.sender, address(this));
      require(tokenAmount >= (addressToLoan[_addressToFund].amountDAI).div(100)
        && ( tokenAmount % 100 ) == 0 ,
        "The amount sent must be a multiplier of 100. Each token costs 100 DAI");

      // If the investor sends more than the MAX_CAP which is 50K
      if( tokenAmount >= 10000 - addressToBalance[_addressToFund] ){
        /* Since each token costs 100 DAI, and the allowance is higher than
          10000 - addressToBalnce[_addressToFund] only the difference will be
          sent to the contract */
        tokensToValue[msg.sender][addressToData[_addressToFund].idNFT] += (10000 - addressToBalance[_addressToFund]).div(100);
        // Insert values in array
        Investors.push(FunderTokens(msg.sender, tokenAmount.div(100), _addressToFund, addressToData[_addressToFund].idNFT));
        // Transfer tokens to the contract

        stableCoinContract.transferFrom(msg.sender, address(this), 10000 - addressToBalance[_addressToFund]);
        // Set true to loan funded, it&#39;s used to track stage of loan
        addressToLoan[_addressToFund].loanFunded = true;
        // AddressToBalance will have 50k when the loan has been funded
        addressToBalance[_addressToFund] +=10000 - addressToBalance[_addressToFund];
        // Instantiate with an initial value of 50K as that&#39;s the amount of the loan
        addressToInvestor[_addressToFund] = 10000;

      }
else{
     // Update shares of the Investor
      tokensToValue[msg.sender][addressToData[_addressToFund].idNFT] += tokenAmount.div(100);
      Investors.push(FunderTokens(msg.sender, 10000 - addressToBalance[_addressToFund].div(100), _addressToFund, addressToData[_addressToFund].idNFT));
      // Add the amount funded to the mapping
      addressToBalance[_addressToFund] += tokenAmount;
      // Transfer DAI to the contract
      stableCoinContract.transferFrom(msg.sender, address(this), tokenAmount);
    }
    }

    /**
      @notice Function to withdraw the loan of the Student
      @param _amount Amount the user is willing to withdraw
    */
    function withdrawLoan(uint _amount) public{
      require(addressToLoan[msg.sender].loanAccepted == true, "Loan was not funded/accepted");
      require(_amount < addressToBalance[msg.sender] || addressToBalance[msg.sender] != 0);
      ERC20 stableCoinContract = ERC20(stableCoinAddress);
      // Transfer the tokens to the school
      stableCoinContract.transfer(addressToUniversity[addressToData[msg.sender].university], _amount);
      // Reduce amount of DAI from the mapping
      addressToBalance[msg.sender] -= _amount;
    }

    /**
      @notice Function to accept the proposed loan
      @param _addressFunded Address of the user funded
    */

    function acceptLoan(address _addressFunded) public onlySchool(_addressFunded){
      require(addressToLoan[_addressFunded].loanFunded == true, "Loan has not been funded completely");
      // Set loan as accepted
      addressToLoan[_addressFunded].loanAccepted = true;
      // Student has been accepted so he has an outstanding loan
      studentHasLoan[_addressFunded] = true;
    }

    /**
      @notice Function used by the Student to repay the Loan
      @dev First you need to call an approve transaction
    */

    function repayLoan() public hasActiveLoan{

        require(addressToLoan[msg.sender].loanRepaid == false, "Loan already repaid");
        ERC20 stableCoinContract = ERC20(stableCoinAddress);
        // amount of DAI that will be used to repay the loan
        uint tokenAmount = stableCoinContract.allowance(msg.sender, address(this));
        // Transfer DAI to the contract
        stableCoinContract.transferFrom(msg.sender, address(this), tokenAmount);
        //Calculate Interest matured
        _calculateInterest(tokenAmount);
        // Check if the loan has been fully repaid
        if(addressToRepaid[msg.sender] == 10000){
          // Set loan repaid as true, Student hasn&#39;t got an outstanding loan anymore
          addressToLoan[msg.sender].loanRepaid = true;
          delete addressToLoan[msg.sender];
          studentHasLoan[msg.sender] = false;
        }
    }

    function _calculateInterest(uint tokenAmount) internal{
      // Calculate the interest
      uint _interest = ( 10000 * (addressToLoan[msg.sender].interestLoan.mul(100)).mul(addressToLoan[msg.sender].startDate.diffDays( now)) ).div(36500);
      // Add tokenAmount to mapping
      addressToRepaid[msg.sender] += tokenAmount.sub(_interest);
      // Add interest to mapping
      studentToInterest[msg.sender] = studentToInterest[msg.sender].add(_interest);
    }

    /**
      @notice Function for the Investors to withdraw their share
      @param _addressFunded Address of the funded student
    */
    function withdrawRepaidLoan(address _addressFunded) public {

            require( addressToLoan[_addressFunded].startDate.diffYears(now) > 4);
            require( addressToLoan[_addressFunded].loanAccepted == true, "Loan was not funded/accepted");
            require( addressToRepaid[_addressFunded] == 10000, "Loan not fully funded");
            ERC20 stableCoinContract = ERC20(stableCoinAddress);
            //Calculate share
            uint share = _calculateRepayment(_addressFunded);
            //ERC20 stableCoinContract = ERC20(stableCoinAddress);
            stableCoinContract.transfer(msg.sender, share);
    }

    function _calculateRepayment(address _addressFunded) internal returns(uint amount) {
      for(uint i = 0; i<Investors.length; i++){
        if(Investors[i]._addressFunded == _addressFunded){
          uint _tokenAmount = tokensToValue[msg.sender][Investors[i].idNFT];
          uint share = (addressToRepaid[_addressFunded].mul(_tokenAmount)).div(100);
          //Reduce token value
          addressToInvestor[_addressFunded] -= share;
          //Reduce amount of tokens
          tokensToValue[msg.sender][Investors[i].idNFT] -= _tokenAmount;
          // Calculate share of interest
          amount = (studentToInterest[_addressFunded].mul(_tokenAmount)).div(100) + share;
          // Reduce Interest
          studentToInterest[_addressFunded] -= (studentToInterest[_addressFunded].mul(_tokenAmount)).div(100);
      }
    }

    }

}