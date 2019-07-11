pragma solidity ^0.5.0;

import "./ERC1155MixedFungibleMintable.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./TimeHelper.sol";
import "./SafeMath.sol";

/**
    @title Providentia, providing students with loan
    @dev See { insert website }
    Note: Some values are hardcoded in order to represent a specific usecase
 */

contract Providentia is Ownable, ERC20, ERC1155MixedFungibleMintable{
  // @dev Library used to calculate time differences
  using BokkyPooBahsDateTimeLibrary for uint;
  using SafeMath for uint;

    // @dev Mapping used to store user data
    mapping( address => StudentData ) public addressToData;
    // @dev Mappiing used to store the details of the Loan
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

    mapping( string => address) addressToUniversity;

        /***********************************|
        |        Variables and Events       |
        |__________________________________*/

    event studentCreated (
        string _name,
        uint _age,
        string _country,
        string _profAccount,
        string _university
        );

    struct StudentData {
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
    }

    struct FunderTokens {
      address _addressFunder;
      uint _amount;
      address _addressFunded;
      uint idNFT;
    }

    FunderTokens[] public Investors;

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
      require( addressToLoan[_addressToFund].loanFunded == false, "User has already a funded loan");
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
      @param _name Name of the Student
      @param _age Age of the Student
      @param _country Country of the Student
      @param _profAccount Github account of the Student
      @param _university University in which the Student is attending to
      @param _uri Used to store the JSON with the data of the Student
    */
    function addStudent(
      address _addressStudent,
      string memory _studentId,
      string memory _name,
      uint _age,
      string memory _country,
      string memory _profAccount,
      string memory _university,
      string memory _uri
    )
      public
      onlySchool(_addressStudent)
    {

        require(bytes(addressToData[_addressStudent].name).length == 0,
        "An address can only have one Student associated");

        require(addressToUniversity[_university] != address(0), "University hasn&#39;t been added yet");

        uint _type = _token.create(_uri, true);
        _token.mintNonFungible(_type, sendTokens);
        uint _id = _token.create(_uri, false);
        _token.mintFungible(_id, sendTokens, valueSend );

        addressToData[_addressStudent] = StudentData(
          _name,
          _age,
          _country,
          _university,
          _profAccount,
          _type
          );

        emit studentCreated(
          _name,
          _age,
          _country,
          _profAccount,
          _university
          );
    }

    function addSchool(
      address _addressSchool,
      string memory _universityName
      )
      public onlyOwner{

        addressToUniversity[_universityName] = _addressSchool;
    }

    /**
      @notice Function used to initiate a Loan process and get funded
      @param _interestLoan Interest rate the student is willing to pay
      @dev For this usecase the Student can request a fixed amount of 50000 DAI
           and have a deadline of 5 years to repay the Loan
    */
    function requestLoan( uint _interestLoan) public hasRequestedLoan{

        //Check if the Student has been added before letting him request a loan
        require(bytes(addressToData[msg.sender].name).length != 0,
        "Student hasn&#39;t been added yet");

        //Update the Mapping
        addressToLoan[msg.sender] = StudentLoan(50000, _interestLoan, 0, now, now.addYears(5), false, false);

        addressToBalance[msg.sender] = 0;
        // When requesting a loan the Student hasn&#39;t accept it yet
        studentHasLoan[msg.sender] = false;

    }

    /**
      @notice Function used to add money to the pool for the Student
      @param _addressToFund Address of the user to be funded
      @dev Each token costs 500 DAI and each token represents a share of the loan

    */
    function addMoneyPool(address _addressToFund) public hasFundedLoan(_addressToFund){
      ERC20 stableCoinContract = ERC20(stableCoinAddress);
      uint tokenAmount = stableCoinContract.allowance(msg.sender, address(this));

      require(tokenAmount >= (addressToLoan[_addressToFund].amountDAI.div(100))
      && ( tokenAmount % 500 ) == 0 ,
      "The amount sent must be a multiplier of 500. Each token costs 500 DAI");

      // If the investor sends more than the MAX_CAP which is 50K
      if( tokenAmount >= 50000 - addressToBalance[_addressToFund] ){
        tokensToValue[msg.sender][addressToData[_addressToFund].idNFT] += (50000 - addressToBalance[_addressToFund]).div(500);
        Investors.push(FunderTokens(msg.sender, tokenAmount.div(500), _addressToFund, addressToData[_addressToFund].idNFT));
        addressToLoan[_addressToFund].loanFunded = true;
        stableCoinContract.transferFrom(msg.sender, address(this), 50000 - addressToBalance[_addressToFund]);
        addressToBalance[_addressToFund] +=50000 - addressToBalance[_addressToFund];

      }
else{
      tokensToValue[msg.sender][addressToData[_addressToFund].idNFT] = tokenAmount.div(500);
      Investors.push(FunderTokens(msg.sender, 50000 - addressToBalance[_addressToFund].div(500), _addressToFund, addressToData[_addressToFund].idNFT));
      addressToBalance[_addressToFund] += tokenAmount;
      stableCoinContract.transferFrom(msg.sender, address(this), tokenAmount);
    }
      //
    }

    /**
      @notice Function to withdraw the loan of the Student
      @param _amount Amount the user is willing to withdraw
    */
    function withdrawLoan(uint _amount) public{
      require(_amount < addressToBalance[msg.sender] || addressToBalance[msg.sender] != 0);
      ERC20 stableCoinContract = ERC20(stableCoinAddress);

      stableCoinContract.transfer(msg.sender, _amount);
    }

    /**
      @notice Function to accept the proposed loan
    */


    function acceptLoan(address _addressFunded) public onlySchool(_addressFunded){
      require(addressToLoan[_addressFunded].loanFunded == true, "Loan has not been funded completely");
      addressToLoan[_addressFunded].loanAccepted = true;
      studentHasLoan[_addressFunded] = true;
    }


/*
      @notice Function to release the tokens to the Investor
      @param _addressFunded Address of the funded User


    function releaseTokens(address _addressFunded) public {

      // check user has 50K
        require( addressToBalance[_addressFunded] == 50000, "Student has not been funded completely");
        //Check user has at least one token
        for( uint i=0; i<Investors.length; i++){
          if(Investors[i]._addressFunded == _addressFunded){
            uint amountStake = tokensToValue[msg.sender][Investors[i].idNFT];
            require( amountStake != 0, "wed");
            _token.safeTransferFrom(sendTokens[0], msg.sender, ownerToTypes[msg.sender][Investors[i].idNFT], amountStake, "onERC1155Received" );
            //Set 0 for the token value
          }
        }
    }*/


    /**
      @notice Function used by the Student to repay the Loan
      @dev First you need to call an approve transaction
    */
    //Check the logic here as it&#39;s a bit flawed
    function repayLoan() public hasActiveLoan{

        ERC20 stableCoinContract = ERC20(stableCoinAddress);
        uint tokenAmount = stableCoinContract.allowance(msg.sender, address(this));

        stableCoinContract.transferFrom(msg.sender, address(this), tokenAmount);
        //Calculate Interest matured
        _calculateInterest(tokenAmount);
    }

    function _calculateInterest(uint tokenAmount) internal{
      uint _interest = ( 50000 * (addressToLoan[msg.sender].interestLoan.mul(100)).mul(addressToLoan[msg.sender].startDate.diffDays( now)) ).div(36500);
    //  addressToBalance[msg.sender].sub(tokenAmount.sub(_interest));
      studentToInterest[msg.sender].add(_interest);
    }

    /**
      @notice Function for the Investors to withdraw their share
      @param _addressFunded Address of the funded student
    */
    function withdrawRepaidLoan(address _addressFunded) public {

            uint share = _calculateRepayment(_addressFunded);
            ERC20 stableCoinContract = ERC20(stableCoinAddress);
            stableCoinContract.transfer(msg.sender, share);

    }

    function _calculateRepayment(address _addressFunded) internal returns(uint share) {
      for(uint i = 0; i<Investors.length; i++){
        if(Investors[i]._addressFunded == _addressFunded){
          uint _tokenAmount = tokensToValue[msg.sender][Investors[i].idNFT];
          share = (addressToBalance[_addressFunded].mul(_tokenAmount.div(100)));
          //Reduce token value
      }
    }

    }

    function getShare(address _addressFunded) public view returns(uint _share){
      for(uint i = 0; i<Investors.length; i++){
        if(Investors[i]._addressFunded == _addressFunded){
          uint _tokenAmount = tokensToValue[msg.sender][Investors[i].idNFT];
          _share = (addressToBalance[_addressFunded].mul(_tokenAmount.div(100)));
          //Reduce token value
      }

    }
  }

  function tokensAmount(address _addressFunded) public view returns(uint _amount){
    for(uint i = 0; i<Investors.length; i++){
      if(Investors[i]._addressFunded == _addressFunded){
        _amount = tokensToValue[msg.sender][Investors[i].idNFT];

    }

  }
  }




}