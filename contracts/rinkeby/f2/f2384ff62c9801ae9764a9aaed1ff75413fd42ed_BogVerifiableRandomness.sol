/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 * $$$$$$$\                   $$$$$$$$\                  $$\           
 * $$  __$$\                  \__$$  __|                 $$ |          
 * $$ |  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$$\ 
 * $$$$$$$\ |$$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ $$ |$$  _____|
 * $$  __$$\ $$ /  $$ |$$ /  $$ |$$ |$$ /  $$ |$$ /  $$ |$$ |\$$$$$$\  
 * $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$ | \____$$\ 
 * $$$$$$$  |\$$$$$$  |\$$$$$$$ |$$ |\$$$$$$  |\$$$$$$  |$$ |$$$$$$$  |
 * \_______/  \______/  \____$$ |\__| \______/  \______/ \__|\_______/ 
 *                     $$\   $$ |                                      
 *                     \$$$$$$  |                                      
 *                      \______/
 * 
 * Bogged Finance
 * Website: https://bogtools.io/
 * Telegram: https://t.me/boggedfinance
 */

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * Provides ownable & authorized contexts 
 */
abstract contract BogAuth {
    address payable _owner;
    mapping (address => bool) _authorizations;
    
    constructor() { 
        _owner = msg.sender; 
        _authorizations[msg.sender] = true;
    }
    
    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }
    
    /**
     * Function modifier to require caller to be contract owner
     */
    modifier owned() {
        require(isOwner(msg.sender)); _;
    }
    
    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(_authorizations[msg.sender] == true); _;
    }
    
    /**
     * Authorize address. Any authorized address
     */
    function authorize(address adr) public authorized {
        _authorizations[adr] = true;
    }
    
    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) external owned {
        _authorizations[adr] = false;
    }
    
    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public owned() {
        _owner = adr;
    }
}

/**
 * Your contract should implement this
 */
interface IReceivesBogRand {
    function receiveRandomness(uint256 random) external;
}

/**
 * You should cast our oracle to this
 */
interface IBogRandOracle {
    function requestRandomness() external;
    
    function getNextHash() external view returns (bytes32);
    function getPendingRequest() external view returns (address);
    function removePendingRequest(address adr, bytes32 nextHash) external;
    function provideRandomness(uint256 random, bytes32 nextHash) external;
    function seed(bytes32 hash) external;
}

interface IFeeProvider {
    function getRandomnessFee() external view returns (uint256);
}

contract TestRand is IReceivesBogRand {
    uint256 public num;
    address rand;
    constructor (address _rand) { _rand = rand; }
    function get() external {
        IBogRandOracle(rand).requestRandomness();
    }
    function receiveRandomness(uint256 random) external override {
        require(msg.sender == rand); // ensure from oracle
        num = random;
    }
}

contract BogVerifiableRandomness is IBogRandOracle, BogAuth {
    using SafeMath for uint256;
    
    // Bogged Finance
    address bog = 0xD7B729ef857Aa773f47D37088A1181bB3fbF0099;
    // Authorized off-chain randomness provider
    address randomnessProvider;
    // Fee provider
    address feeProvider;
    
    address[] requests;
    bytes32[] hashes;
    uint256 pending;
    
    constructor (address _provider) {
        randomnessProvider = _provider;
    }
    
    modifier onlyProvider() {
        require(msg.sender == randomnessProvider); _;
    }
    
    function seed(bytes32 hash) external override onlyProvider {
        require(hashes.length == 0);
        addNextHash(hash);
    }
    
    function requestRandomness() external override {
        require(hashes.length > 0, "Not yet seeded");
        takeFee(msg.sender);
        requests.push(msg.sender);
    }
    
    function provideRandomness(uint256 random, bytes32 nextHash) external override onlyProvider {
        IReceivesBogRand(getPendingRequest()).receiveRandomness(random);
        addNextHash(nextHash);
        pending++;
    }
    
    function getNextHash() external view override returns (bytes32) {
        require(hashes.length > 0, "Not yet seeded");
        return hashes[hashes.length - 1];
    }
    
    /**
     * Returns address of pending request, or zero address if none
     */
    function getPendingRequest() public view override returns (address) {
        if(pending == requests.length){ return address(0); }
        return requests[pending];
    }
    
    /**
     * Can be called to bypass a pending request if the randomness provision tx is failing for some reason (failure in receiving code / too much gas / etc.)
     */
    function removePendingRequest(address adr, bytes32 nextHash) external override onlyProvider {
        require(adr == getPendingRequest());
        addNextHash(nextHash);
        pending++;
    }
    
    function addNextHash(bytes32 hash) internal {
        hashes.push(hash);
        emit NextHash(hash);
    }
    
    /**
     * Take fee from sender
     */
    function takeFee(address from) internal {
        // implement fees later
    }
    
    /**
     * Flat fee of 1 BOG to begin with but allow fees to be determined by a fee provider in the future
     */
    function getFee() public view returns (uint256) {
        if(feeProvider == address(0)){ return 1 * (10 ** 18); }
        return IFeeProvider(feeProvider).getRandomnessFee();
    }
    
    /**
     * Change the fee provider
     */
    function useFeeProvider(address adr) external authorized {
        feeProvider = adr;
    }
    
    event NextHash(bytes32 hash);
}