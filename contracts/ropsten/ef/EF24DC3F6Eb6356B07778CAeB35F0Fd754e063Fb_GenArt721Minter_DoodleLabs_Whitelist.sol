pragma solidity ^0.5.0;

import './IGenArt721CoreV2.sol';
import './SafeMath.sol';

contract GenArt721Minter_DoodleLabs_Whitelist {
    using SafeMath for uint256;

    event AddWhitelist();

    IGenArt721CoreV2 genArtCoreContract;
    address public minterAddress;

    mapping(uint256 => mapping(address => uint256)) public whitelist;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
        _;
    }

    constructor(address _genArtCore, address _minterAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCore);
        minterAddress = _minterAddress;
    }

    function getWhitelisted(uint256 projectId, address user) external view returns (uint256 amount) {
        return whitelist[projectId][user];
    }

    function addWhitelist(uint256 projectId, address[] memory users, uint256[] memory amounts) public onlyWhitelisted {
        require(users.length == amounts.length, 'users amounts array mismatch');

        for (uint i = 0; i < users.length; i++) {
            whitelist[projectId][users[i]] = amounts[i];
        }
        emit AddWhitelist();
    }

    function decreaseAmount(uint256 projectId, address to) public {
        require(msg.sender == minterAddress, "only callable by minter");
        require(whitelist[projectId][to] > 0, "user has nothing to redeem");
        whitelist[projectId][to] = whitelist[projectId][to].sub(1);
    }

}