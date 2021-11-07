pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Accounts.sol";
import "./interfaces/IStorage.sol";

contract Core is Initializable, OwnableUpgradeable {
       /// ** PUBLIC states **

    address public storage_;
    uint16 public constant MAX_COURSES_FOR_STUDENTS = 32;
    uint16 public constant MAX_COURSES_FOR_TEACHERS = 16;
    uint16 public constant MAX_STUDENTS_FOR_COURSE = 256;

    /// ** PRIVATE states **

    /// ** STRUCTS **

    /// ** EVENTS **

    event StudentCreated(uint256 studentID);

    event TeacherCreated(uint256 teacherID);

    event CourseCreated(uint256 courseID);

    event StudentInfo(
        uint256 id,
        string name,
        uint256 groupID,
        uint256 credentialID,
        address account,
        uint256[] courses
    );

    event TeacherInfo(
        uint256 id,
        string name,
        address account,
        uint256[] courses
    );

    event CourseInfo(
        uint256 id,
        string name,
        uint256[] students,
        uint256 teacher
    );

    /// ** MODIFIERs **

    /// ** INITIALIZER **

    function initialize(address _storage) public virtual initializer {
        __Ownable_init();

        storage_ = _storage;
    }

    /// ** PUBLIC functions **

    // ** EXTERNAL functions **

    function addStudent(
        string memory _name,
        uint256 _groupID,
        uint256 _credentialID,
        address _account
    ) external onlyOwner {
        accounts.Student memory student = accounts.Student({
            name: _name,
            groupID: _groupID,
            credentialID: _credentialID,
            account: _account,
            courses: new uint256[](MAX_COURSES_FOR_STUDENTS)
        });

        uint256 studentID = IStorage(storage_).addStudent(student);

        emit StudentCreated(studentID);
    }

    function addTeacher(string memory _name, address _account)
        external
        onlyOwner
    {
        accounts.Teacher memory teacher = accounts.Teacher({
            name: _name,
            account: _account,
            courses: new uint256[](MAX_COURSES_FOR_TEACHERS)
        });

        uint256 teacherID = IStorage(storage_).addTeacher(teacher);

        emit TeacherCreated(teacherID);
    }

    function addCourse(string memory _name, uint256 _teacher)
        external
        onlyOwner
    {
        accounts.Course memory course = accounts.Course({
            name: _name,
            students: new uint256[](MAX_STUDENTS_FOR_COURSE),
            teacher: _teacher
        });

        uint256 courseID = IStorage(storage_).addCourse(course);

        emit CourseCreated(courseID);
    }

    function getStudent(uint256 studentID)
        external
    {
        accounts.Student memory student = IStorage(storage_).getStudent(studentID);

        emit StudentInfo(
            studentID,
            student.name,
            student.groupID,
            student.credentialID,
            student.account,
            student.courses
        );
    }

    function getTeacher(uint256 teacherID)
        external
    {
        accounts.Teacher memory teacher = IStorage(storage_).getTeacher(teacherID);

        emit TeacherInfo(
            teacherID,
            teacher.name,
            teacher.account,
            teacher.courses
        );
    }

    function getCourse(uint256 courseID)
        external
    {
        accounts.Course memory course = IStorage(storage_).getCourse(courseID);

        emit CourseInfo(
            courseID,
            course.name,
            course.students,
            course.teacher
        );
    }

    /// ** INTERNAL functions **
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

pragma solidity ^0.8.7;

library accounts {
    struct Student {
        string name;
        uint256 groupID;
        uint256 credentialID;
        address account;
        uint256[] courses; // IDs of courses, m2m
    }

    struct Teacher {
        string name;
        address account;
        uint256[] courses; // IDs of courses, o2m
    }

    struct Course {
        string name;
        uint256[] students; //IDs of students, m2m
        uint256 teacher; // ID of teacher
        // uint256 duration;
        // ??? schedule;
    }
}

pragma solidity ^0.8.7;

import "../Accounts.sol";

interface IStorage {
    function addStudent(
        accounts.Student memory student
    ) external returns (uint256);

    function addTeacher(
        accounts.Teacher memory teacher
    ) external returns (uint256);

    function addCourse(
        accounts.Course memory course
    ) external returns (uint256);

    function getStudent(uint256 studentID)
        external
        view
        returns (accounts.Student memory);

    function getTeacher(uint256 teacherID)
        external
        view
        returns (accounts.Teacher memory);

    function getCourse(uint256 courseID)
        external
        view
        returns (accounts.Course memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}