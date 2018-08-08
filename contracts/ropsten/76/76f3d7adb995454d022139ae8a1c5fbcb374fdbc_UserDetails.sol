pragma solidity ^0.4.19;

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

/**
 * @title = UserDetails
 * This contract saves users education details , certification details , profile details to their perspective
 * email ids .
 */
contract UserDetails is Ownable {
    string userEmail;

    struct education {
        string nameOfIntitution;
        uint16 yearOfPassing;
    }

    struct certification {
        string certificationUrl;
        string certificationName;
        string certificationProvider;
        uint16 yearOfCertification;
    }

    struct profileDetails {
        string bio;
    }
    enum educationQualification{SSc,HSc,college}
    educationQualification educationQualificationOf;

    mapping(string => mapping(uint => education)) education_of;
    mapping(string => mapping(uint => certification)) certificationOf;
    mapping(string => profileDetails) profileDetailsOf;

    event EducationUpdate(string indexed _userEmail, education );
    event CertificationUpdate(string indexed _userEmail, certification );
    event ProfileUpdate(string indexed _userEmail,profileDetails);
    event UserEmailUpdate(string indexed _userEmail);

    /*
     * @setUserEmail function sets user email takes one argument.
     * @_userEmail user email of student/user.
     */
    function setUserEmail(string _userEmail) public {
        userEmail = _userEmail;
        emit UserEmailUpdate(userEmail);
    }

    /*
     * @updateEducation function sets edication details of user
     * and map it to setted user emailid takes 3 argument. only owner can perform.
     * @_index its value must be ranging from 0 to 2 depicting SSc , HSc, college respectively.
     * @_nameOfIntitution name of institution of user.
     * @_yearOfPassing year of passing of user.
     */
    function updateEducation(
      uint _index,
      string _nameOfIntitution,
      uint16 _yearOfPassing
      ) public onlyOwner {
        education memory _education = education(_nameOfIntitution,_yearOfPassing);
        education_of[userEmail][_index]=_education;
        emit EducationUpdate(userEmail, _education);
      }

    /*
     * @updateCertification function certification details of user
     * and map it to setted user emailid takes 4 argument.  only owner can perform.
     * @_index it shows no. of certifictes.
     * @_certificationUrl url as string, of certificate.
     * @_certificationName name of certificate as string.
     * @_certificationProvider name of certificate Provider as string.
     * @_yearOfCertification year in which user complete its certificate.
     */
    function updateCertification(
      uint _index,
      string _certificationUrl,
      string _certificationName,
      string _certificationProvider,
      uint16 _yearOfCertification
      ) public onlyOwner {
        certification memory _certification = certification(
          _certificationUrl,
          _certificationName,
          _certificationProvider,
          _yearOfCertification
          );
        certificationOf[userEmail][_index] = _certification;
        emit CertificationUpdate(userEmail, _certification);
      }

    /*
     * @updateProfileDetails function sets the profile details of user
     * and map it to setted user emailid takes 1 argument.
     * only owner can perform.
     * @_bio user can write about him.
     */
    function updateProfileDetails(string _bio) public onlyOwner {
      profileDetails memory _profileDetails = profileDetails(_bio);
      emit ProfileUpdate(userEmail, _profileDetails);
    }

    /*
     * @showCertificationDetails function return certification details of user of perticular email id
     * as set in state varible userEmail. it takes one argument.
     * @_index certification no.
     */
    function showCertificationDetails(uint _index) public view returns(
      string _certificationUrl,
      string _certificationName,
      string _certificationProvider,
      uint _yearOfCertification
      ) {
        _certificationUrl = certificationOf[userEmail][_index].certificationUrl;
        _certificationName = certificationOf[userEmail][_index].certificationName;
        _certificationProvider = certificationOf[userEmail][_index].certificationProvider;
        _yearOfCertification = certificationOf[userEmail][_index].yearOfCertification;
      }

    /*
     * @showEducationDetails function return education details of user of perticular email id
     * as set in state varible userEmail. it takes one argument.
     * @_index certification no.
     */
    function showEducationDetails(uint _index) public view returns(
      string _nameOfIntitution,
      uint _yearOfPassing
      ) {
        _nameOfIntitution = education_of[userEmail][_index].nameOfIntitution;
        _yearOfPassing = education_of[userEmail][_index].yearOfPassing;
      }

    /*
     * @showProfileDetails function return profile details of user of perticular email id
     * as set in state varible userEmail.
     */
    function showProfileDetails() public view returns(string _bio) {
        _bio = profileDetailsOf[userEmail].bio;
    }
}