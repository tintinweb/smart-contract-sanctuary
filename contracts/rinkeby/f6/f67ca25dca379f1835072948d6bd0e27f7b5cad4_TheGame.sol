/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

//SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: contracts/MainGame.sol

pragma solidity^0.8.0;


contract TheGame is Ownable {
    mapping(uint256 => bytes32[]) private answers;
    mapping(address => uint256[]) public correctAnswers;
    
    modifier onlyHuman{
        // an attempt to mitigate people writing contracts to automate against this.
        // source: RealWorld CTF 2018
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size==0);
        _;
    }
    // https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
    
    function setAns(uint256 _question, bytes32[] memory _answer) public onlyOwner {
        answers[_question] = _answer;
    }
    
    function getAns(uint256 _question) internal view returns(bytes32[] memory) {
        require(answers[_question].length >0, "This answer has not been set, if you expect it to be please contact the game admin");
        return answers[_question];
    }
    
    function addAnsMap(uint256 _question, address answerer) public view returns(bool){
        uint256[] storage answersSoFar = correctAnswers[answerer];
        for (uint256 i=0; i < answersSoFar.length; i++) {
            if (answersSoFar[i] == _question) {
                return false;
            }
        }
        return true;
    }
    event correctAnswer(address submitter, uint256 q);
    function checkAnswer(uint256 _question, uint256[] memory _wordNums, bytes32[] memory _words) public returns(bool) {
        bytes32[] memory fullAns = answers[_question];
        for (uint256 i=0; i <= _wordNums.length; i++) {
            bytes32 real = fullAns[i];
            if (_words[i] != real) {
                return false;
            }
        }
        if (addAnsMap(_question, msg.sender)) {
               uint256[] storage alreadyAnswered = correctAnswers[msg.sender];
               alreadyAnswered.push(_question);
               correctAnswers[msg.sender] = alreadyAnswered;
        }
        return true;
    }
    
    function getKek(string memory _given) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_given));
    }
    
    function getAlreadyAnswered(string memory user) public view returns(uint256) {
        uint256[] memory correct_ = correctAnswers[parseAddr(user)];
        return correct_.length;
    }
    
    function totalQuestions() public pure returns(uint256) {
        return 12;
    }
    
    function prizePool() public pure returns(uint256) {
        return 100000;
    }
    
    fallback() external payable {} // called if a none existent function is called
    receive() external payable {} // called if ether is sent to the contract without a function call
}