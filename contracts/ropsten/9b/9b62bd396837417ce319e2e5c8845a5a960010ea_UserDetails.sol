pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/*
 * @title = UserDetails
 * This contract saves users education details , certification details , profile details to their perspective
 * email ids .
 */
contract UserDetails is Ownable {
    
    struct User {
        string email;
        string bio;
    }
    
    struct Education {
        string nameOfIntitution;
        uint16 yearOfPassing;
        string educationtype;
    }

    struct Certification {
        string certificationUrl;
        string certificationName;
        string certificationProvider;
        uint16 yearOfCertification;
    }

    
    enum educationQualification{SSc,HSc,college}
    educationQualification educationQualificationOf;
    
    mapping(string => User) user_details;
    mapping(string => mapping(uint => Education)) user_education;
    mapping(string => Certification) user_certification;

    event UserEducationUpdate(string indexed _userEmail, string, string, uint);
    event UserCertificationUpdate(string indexed _userEmail, string, string, string, uint );
    event UserBioUpdate(string indexed _userEmail,string);
    event UserEmailUpdate(string indexed _userEmail);
    
/*
 * @UpdateUserEmail function sets user email takes one argument.
 * @_userEmail user email of student/user.
 */
    function UpdateUserEmail(string _userEmail) public onlyOwner returns(bool){
        user_details[_userEmail].email = _userEmail;
        emit UserEmailUpdate(_userEmail);
        return true;
    }
    
/*
 * @updateUserBio function sets the bio of user
 * and map it to setted user emailid takes 2 argument.
 * only owner can perform.
 * @_userEmail user email
 * @_bio user can write about him.
 */
    function updateUserBio(string _userEmail, string _bio) public onlyOwner returns(bool) {
      user_details[_userEmail].bio = _bio;
      emit UserBioUpdate(_userEmail, _bio);
      return true;
    }

/*
 * @updateUserEducation function sets edication details of user
 * and map it to setted user emailid takes 4 argument. only owner can perform.
 * @_userEmail user email
 * @_index its value must be ranging from 0 to 2 depicting SSc , HSc, college respectively.
 * @_nameOfIntitution name of institution of user.
 * @_yearOfPassing year of passing of user.
 */
    function updateUserEducation(
      string _userEmail,
      uint _index,
      string _nameOfIntitution,
      uint16 _yearOfPassing
      ) public onlyOwner returns(bool) {
        Education memory _education = Education(
          _nameOfIntitution,
          _yearOfPassing,
          _SetEducationQualificationOf(_index)
          );
        user_education[_userEmail][_index]=_education;
        emit UserEducationUpdate(
          _userEmail,
          user_education[_userEmail][_index].educationtype,
          user_education[_userEmail][_index].nameOfIntitution,
          user_education[_userEmail][_index].yearOfPassing
          );
          return true;
      }

/*
 * @updateCertification function certification details of user
 * and map it to setted user emailid takes 5 argument.  only owner can perform.
 * @_userEmail user email
 * @_certificationUrl url as string, of certificate.
 * @_certificationName name of certificate as string.
 * @_certificationProvider name of certificate Provider as string.
 * @_yearOfCertification year in which user complete its certificate.
 */
    function updateUserCertification(
      string _userEmail,
      string _certificationUrl,
      string _certificationName,
      string _certificationProvider,
      uint16 _yearOfCertification
      ) public onlyOwner returns(bool) {
        Certification memory _certification = Certification(
          _certificationUrl,
          _certificationName,
          _certificationProvider,
          _yearOfCertification
          );
        user_certification[_userEmail] = _certification;
        emit UserCertificationUpdate(
          _userEmail,
          user_certification[_userEmail].certificationUrl,
          user_certification[_userEmail].certificationName,
          user_certification[_userEmail].certificationProvider,
          user_certification[_userEmail].yearOfCertification
          );
          return true;
      }
      


/*
 * @getUserCertificationDetails function return certification details of user of perticular email id
 * as set in state varible userEmail. it takes one argument.
 * @_index certification no.
 */
    function getUserCertificationDetails(string _userEmail) public view returns(
      string _certificationUrl,
      string _certificationName,
      string _certificationProvider,
      uint _yearOfCertification
      ) {
        _certificationUrl = user_certification[_userEmail].certificationUrl;
        _certificationName = user_certification[_userEmail].certificationName;
        _certificationProvider = user_certification[_userEmail].certificationProvider;
        _yearOfCertification = user_certification[_userEmail].yearOfCertification;
      }
      
      function getUserSSCeducationDetails(string _userEmail) public view returns(
      string _nameOfIntitution,
      uint _yearOfPassing,
      string  _educatiodetailType
      ) {
        _nameOfIntitution = user_education[_userEmail][0].nameOfIntitution;
        _yearOfPassing = user_education[_userEmail][0].yearOfPassing;
        _educatiodetailType = user_education[_userEmail][0].educationtype;
      }
      
      function getUserHSCeducationDetails(string _userEmail) public view returns(
      string _nameOfIntitution,
      uint _yearOfPassing,
      string  _educatiodetailType
      ) {
        _nameOfIntitution = user_education[_userEmail][1].nameOfIntitution;
        _yearOfPassing = user_education[_userEmail][1].yearOfPassing;
        _educatiodetailType = user_education[_userEmail][1].educationtype;
      }
      
      function getUserCollegeEducationDetails(string _userEmail) public view returns(
      string _nameOfIntitution,
      uint _yearOfPassing,
      string  _educatiodetailType
      ) {
        _nameOfIntitution = user_education[_userEmail][2].nameOfIntitution;
        _yearOfPassing = user_education[_userEmail][2].yearOfPassing;
        _educatiodetailType = user_education[_userEmail][2].educationtype;
      }



/*
 * @getUserBio function return profile details of user of perticular email id
 * as set in state varible userEmail.
 */
    function getUserBio(string _userEmail) public view returns(string _bio) {
        _bio = user_details[_userEmail].bio;
    }

  function _SetEducationQualificationOf(uint _index) private returns(string){
     require(_index<3);
     if(_index==0){
         educationQualificationOf= educationQualification.SSc;
         return("SSc");
     } else if(_index==1) {
         educationQualificationOf= educationQualification.HSc;
         return("HSc");
     } else {
     educationQualificationOf= educationQualification.college;
     return("college");
     }
 }
}