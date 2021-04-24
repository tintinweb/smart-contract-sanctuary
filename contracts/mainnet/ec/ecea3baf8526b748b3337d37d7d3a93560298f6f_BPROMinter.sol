/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/minter.sol

pragma solidity ^0.5.16;

//import "./BPRO.sol";


contract BPROLike {
    function mint(address to, uint qty) external;
    function setMinter(address newMinter) external;
}

// initially deployer owns it, and then it moves it to the DAO
contract BPROMinter is Ownable {
    address public reservoir;
    address public devPool;
    address public userPool;
    address public backstopPool;
    address public genesisPool;

    uint public deploymentBlock;
    uint public deploymentTime;
    mapping(bytes32 => uint) lastDripBlock;

    BPROLike public bpro;

    uint constant BLOCKS_PER_YEAR = 4 * 60 * 24 * 365;
    uint constant BLOCKS_PER_MONTH = (BLOCKS_PER_YEAR / 12);

    uint constant YEAR = 365 days;

    event MinterSet(address newMinter);
    event DevPoolSet(address newPool);
    event BackstopPoolSet(address newPool);
    event UserPoolSet(address newPool);
    event ReservoirSet(address newPool);

    constructor(BPROLike _bpro, address _reservoir, address _devPool, address _userPool, address _backstopPool) public {
        reservoir = _reservoir;
        devPool = _devPool;

        userPool = _userPool;
        backstopPool = _backstopPool;

        deploymentBlock = getBlockNumber();
        deploymentTime = now;

        bpro = _bpro;

        // this will be pre minted before ownership transfer
        //bpro.mint(_genesisMakerPool, 500_000e18);
        //bpro.mint(_genesisCompoundPool, 500_000e18);        
    }

    function dripReservoir() external {
        drip(reservoir, "reservoir", 1_325_000e18 / BLOCKS_PER_YEAR, uint(-1));
    }

    function dripDev() external {
        drip(devPool, "devPool", 825_000e18 / BLOCKS_PER_YEAR, uint(-1));
    }

    function dripUser() external {
        uint dripPerMonth = 250_000e18 / uint(3);

        drip(userPool, "dripUser", dripPerMonth / BLOCKS_PER_MONTH, deploymentBlock + BLOCKS_PER_MONTH * 3);
    }

    function dripBackstop() external {
        drip(backstopPool, "dripBackstop", 150_000e18 / BLOCKS_PER_YEAR, deploymentBlock + BLOCKS_PER_YEAR);
    }

    function setMinter(address newMinter) external onlyOwner {
        require(now > deploymentTime + 4 * YEAR, "setMinter: wait-4-years");
        bpro.setMinter(newMinter);

        emit MinterSet(newMinter);
    }

    function setDevPool(address newPool) external onlyOwner {
        require(now > deploymentTime + YEAR, "setDevPool: wait-1-years");
        devPool = newPool;

        emit DevPoolSet(newPool);
    }

    function setBackstopPool(address newPool) external onlyOwner {
        backstopPool = newPool;

        emit BackstopPoolSet(newPool);
    }

    function setUserPool(address newPool) external onlyOwner {
        userPool = newPool;

        emit UserPoolSet(newPool);
    }

    function setReservoir(address newPool) external onlyOwner {
        reservoir = newPool;

        emit ReservoirSet(newPool);
    }

    function drip(address target, bytes32 targetName, uint dripRate, uint finalDripBlock) internal {
        uint prevDripBlock = lastDripBlock[targetName];
        if(prevDripBlock == 0) prevDripBlock = deploymentBlock;

        uint currBlock = getBlockNumber();
        if(currBlock > finalDripBlock) currBlock = finalDripBlock;

        require(currBlock > prevDripBlock, "drip: bad-block");

        uint deltaBlock = currBlock - prevDripBlock;
        lastDripBlock[targetName] = currBlock;

        uint mintAmount = deltaBlock * dripRate;
        bpro.mint(target, mintAmount);
    }

    function getBlockNumber() public view returns(uint) {
        return block.number;
    }
}

contract MockMiner is BPROMinter {
    uint blockNumber;

    constructor(BPROLike _bpro, address _reservoir, address _devPool, address _userPool, address _backstopPool) public 
        BPROMinter(_bpro,_reservoir,_devPool,_userPool,_backstopPool)
    {
        blockNumber = block.number;
    }

    function fwdBlockNumber(uint delta) public {
        blockNumber += delta;
    }

    function getBlockNumber() public view returns(uint) {
        if(blockNumber == 0) return block.number;

        return blockNumber;
    }
}