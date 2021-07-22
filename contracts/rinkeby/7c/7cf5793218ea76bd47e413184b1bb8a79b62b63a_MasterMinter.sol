/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

/**
 *Submitted for verification at Etherscan.io on 2019-03-14
*/

pragma solidity ^0.4.24;

// File: contracts/Ownable.sol

/**
* Copyright CENTRE SECZ 2018
*
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is furnished to 
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract from https://github.com/zeppelinos/labs/blob/master/upgradeability_ownership/contracts/ownership/Ownable.sol 
 * branch: master commit: 3887ab77b8adafba4a26ace002f3a684c1a3388b modified to:
 * 1) Add emit prefix to OwnershipTransferred event (7/13/18)
 * 2) Replace constructor with constructor syntax (7/13/18)
 * 3) consolidate OwnableStorage into this contract
 */
contract Ownable {

  // Owner of the contract
  address private _owner;

  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address previousOwner, address newOwner);

  /**
  * @dev The constructor sets the original owner of the contract to the sender account.
  */
  constructor() public {
    setOwner(msg.sender);
  }

  /**
 * @dev Tells the address of the owner
 * @return the address of the owner
 */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

// File: contracts/minting/Controller.sol

/**
* Copyright CENTRE SECZ 2018
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

pragma solidity ^0.4.24;


/**
 * @title Controller
 * @notice Generic implementation of the owner-controller-worker model.
 * One owner manages many controllers. Each controller manages one worker.
 * Workers may be reused across different controllers.
 */
contract Controller is Ownable {
    /**
     * @notice A controller manages a single worker address.
     * controllers[controller] = worker
     */
    mapping(address => address) internal controllers;

    event ControllerConfigured(
        address indexed _controller,
        address indexed _worker
    );
    event ControllerRemoved(address indexed _controller);

    /**
     * @notice Ensures that caller is the controller of a non-zero worker 
     * address.
     */
    modifier onlyController() {
        require(controllers[msg.sender] != address(0), 
            "The value of controllers[msg.sender] must be non-zero");
        _;
    }

    /**
     * @notice Gets the worker at address _controller.
     */
    function getWorker(
        address _controller
    )
        external
        view
        returns (address)
    {
        return controllers[_controller];
    }

    // onlyOwner functions

    /**
     * @notice Configure a controller with the given worker.
     * @param _controller The controller to be configured with a worker.
     * @param _worker The worker to be set for the newly configured controller.
     * _worker must not be a non-zero address. To disable a worker,
     * use removeController instead.
     */
    function configureController(
        address _controller,
        address _worker
    )
        public 
        onlyOwner 
    {
        require(_controller != address(0), 
            "Controller must be a non-zero address");
        require(_worker != address(0), "Worker must be a non-zero address");
        controllers[_controller] = _worker;
        emit ControllerConfigured(_controller, _worker);
    }

    /**
     * @notice disables a controller by setting its worker to address(0).
     * @param _controller The controller to disable.
     */
    function removeController(
        address _controller
    )
        public 
        onlyOwner 
    {
        require(_controller != address(0), 
            "Controller must be a non-zero address");
        require(controllers[_controller] != address(0), 
            "Worker must be a non-zero address");
        controllers[_controller] = address(0);
        emit ControllerRemoved(_controller);
    }
}

// File: contracts/minting/MinterManagementInterface.sol

/**
* Copyright CENTRE SECZ 2019
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

pragma solidity ^0.4.24;

/** 
 * @notice A contract that implements the MinterManagementInterface has external 
 * functions for adding and removing minters and modifying their allowances. 
 * An example is the FiatTokenV1 contract that implements USDC.
 */
interface MinterManagementInterface {
    function isMinter(address _account) external view returns (bool);
    function minterAllowance(address _minter) external view returns (uint256);

    function configureMinter(
        address _minter,
        uint256 _minterAllowedAmount
    )
        external
        returns (bool);

    function removeMinter(address _minter) external returns (bool);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/minting/MintController.sol

/**
* Copyright CENTRE SECZ 2018
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

pragma solidity ^0.4.24;




/**
 * @title MintController
 * @notice The MintController contract manages minters for a contract that 
 * implements the MinterManagerInterface. It lets the owner designate certain 
 * addresses as controllers, and these controllers then manage the 
 * minters by adding and removing minters, as well as modifying their minting 
 * allowance. A controller may manage exactly one minter, but the same minter 
 * address may be managed by multiple controllers.
 * @dev MintController inherits from the Controller contract. It treats the 
 * Controller workers as minters.
 */
contract MintController is Controller {
    using SafeMath for uint256;

    /**
    * @title MinterManagementInterface
    * @notice MintController calls the minterManager to execute/record minter 
    * management tasks, as well as to query the status of a minter address.
    */
    MinterManagementInterface internal minterManager;

    event MinterManagerSet(
        address indexed _oldMinterManager,
        address indexed _newMinterManager
    );
    event MinterConfigured(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _allowance
    );
    event MinterRemoved(
        address indexed _msgSender,
        address indexed _minter
    );
    event MinterAllowanceIncremented(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _increment,
        uint256 _newAllowance
    );

    event MinterAllowanceDecremented(
        address indexed msgSender,
        address indexed minter,
        uint256 decrement,
        uint256 newAllowance
    );

    /**
     * @notice Initializes the minterManager.
     * @param _minterManager The address of the minterManager contract.
     */
    constructor(address _minterManager) public {
        minterManager = MinterManagementInterface(_minterManager);
    }

    /**
     * @notice gets the minterManager
     */
    function getMinterManager(
    )
        external
        view
        returns (MinterManagementInterface)
    {
        return minterManager;
    }

    // onlyOwner functions

    /**
     * @notice Sets the minterManager.
     * @param _newMinterManager The address of the new minterManager contract.
     */
    function setMinterManager(
        address _newMinterManager
    )
        public
        onlyOwner
    {
        emit MinterManagerSet(address(minterManager), _newMinterManager);
        minterManager = MinterManagementInterface(_newMinterManager);
    }

    // onlyController functions

    /**
     * @notice Removes the controller's own minter.
     */
    function removeMinter() public onlyController returns (bool) {
        address minter = controllers[msg.sender];
        emit MinterRemoved(msg.sender, minter);
        return minterManager.removeMinter(minter);
    }

    /**
     * @notice Enables the minter and sets its allowance.
     * @param _newAllowance New allowance to be set for minter.
     */
    function configureMinter(
        uint256 _newAllowance
    )
        public
        onlyController
        returns (bool)
    {
        address minter = controllers[msg.sender];
        emit MinterConfigured(msg.sender, minter, _newAllowance);
        return internal_setMinterAllowance(minter, _newAllowance);
    }

    /**
     * @notice Increases the minter's allowance if and only if the minter is an 
     * active minter.
     * @dev An minter is considered active if minterManager.isMinter(minter) 
     * returns true.
     */
    function incrementMinterAllowance(
        uint256 _allowanceIncrement
    )
        public
        onlyController
        returns (bool)
    {
        require(_allowanceIncrement > 0, 
            "Allowance increment must be greater than 0");
        address minter = controllers[msg.sender];
        require(minterManager.isMinter(minter), 
            "Can only increment allowance for minters in minterManager");

        uint256 currentAllowance = minterManager.minterAllowance(minter);
        uint256 newAllowance = currentAllowance.add(_allowanceIncrement);

        emit MinterAllowanceIncremented(
            msg.sender,
            minter,
            _allowanceIncrement,
            newAllowance
        );

        return internal_setMinterAllowance(minter, newAllowance);
    }

    /**
     * @notice decreases the minter allowance if and only if the minter is
     * currently active. The controller can safely send a signed 
     * decrementMinterAllowance() transaction to a minter and not worry 
     * about it being used to undo a removeMinter() transaction.
     */
    function decrementMinterAllowance(
        uint256 _allowanceDecrement
    )
        public
        onlyController
        returns (bool)
    {
        require(_allowanceDecrement > 0, 
            "Allowance decrement must be greater than 0");
        address minter = controllers[msg.sender];
        require(minterManager.isMinter(minter), 
            "Can only decrement allowance for minters in minterManager");

        uint256 currentAllowance = minterManager.minterAllowance(minter);
        uint256 actualAllowanceDecrement = (
            currentAllowance > _allowanceDecrement ? 
            _allowanceDecrement : currentAllowance
        );
        uint256 newAllowance = currentAllowance.sub(actualAllowanceDecrement);

        emit MinterAllowanceDecremented(
            msg.sender,
            minter,
            actualAllowanceDecrement,
            newAllowance
        );

        return internal_setMinterAllowance(minter, newAllowance);
    }

    // Internal functions

    /**
     * @notice Uses the MinterManagementInterface to enable the minter and
     * set its allowance.
     * @param _minter Minter to set new allowance of.
     * @param _newAllowance New allowance to be set for minter.
     */
    function internal_setMinterAllowance(
        address _minter,
        uint256 _newAllowance
    )
        internal
        returns (bool)
    {
        return minterManager.configureMinter(_minter, _newAllowance);
    }
}

// File: contracts/minting/MasterMinter.sol

/**
* Copyright CENTRE SECZ 2018
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

pragma solidity ^0.4.24;


/**
 * @title MasterMinter
 * @notice MasterMinter uses multiple controllers to manage minters for a 
 * contract that implements the MinterManagerInterface.
 * @dev MasterMinter inherits all its functionality from MintController.
 */
contract MasterMinter is MintController {

    constructor(address _minterManager) MintController(_minterManager) public {
    }
}