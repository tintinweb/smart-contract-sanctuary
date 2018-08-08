contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address _who) view public returns (bool);
}

contract ERC223ReceivingContract {

    /// @dev Standard ERC223 function that will handle incoming token transfers.
    /// @param _from  Token sender address.
    /// @param _value Amount of tokens.
    /// @param _data  Transaction metadata.
    function tokenFallback(address _from, uint _value, bytes _data) public;

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223Basic is ERC20Basic {

    /**
      * @dev Transfer the specified amount of tokens to the specified address.
      *      Now with a new parameter _data.
      *
      * @param _to    Receiver address.
      * @param _value Amount of tokens that will be transferred.
      * @param _data  Transaction metadata.
      */
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

    /**
      * @dev triggered when transfer is successfully called.
      *
      * @param _from  Sender address.
      * @param _to    Receiver address.
      * @param _value Amount of tokens that will be transferred.
      * @param _data  Transaction metadata.
      */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _value, bytes _data);
}


contract SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract DetherBank is ERC223ReceivingContract, Ownable, SafeMath  {
  using BytesLib for bytes;

  /*
   * Event
   */
  event receiveDth(address _from, uint amount);
  event receiveEth(address _from, uint amount);
  event sendDth(address _from, uint amount);
  event sendEth(address _from, uint amount);

  mapping(address => uint) public dthShopBalance;
  mapping(address => uint) public dthTellerBalance;
  mapping(address => uint) public ethShopBalance;
  mapping(address => uint) public ethTellerBalance;

  ERC223Basic public dth;
  bool public isInit = false;

  /**
   * INIT
   */
  function setDth (address _dth) external onlyOwner {
    require(!isInit);
    dth = ERC223Basic(_dth);
    isInit = true;
  }

  /**
   * Core fonction
   */
  // withdraw DTH when teller delete
  function withdrawDthTeller(address _receiver) external onlyOwner {
    require(dthTellerBalance[_receiver] > 0);
    uint tosend = dthTellerBalance[_receiver];
    dthTellerBalance[_receiver] = 0;
    require(dth.transfer(_receiver, tosend));
  }
  // withdraw DTH when shop delete
  function withdrawDthShop(address _receiver) external onlyOwner  {
    require(dthShopBalance[_receiver] > 0);
    uint tosend = dthShopBalance[_receiver];
    dthShopBalance[_receiver] = 0;
    require(dth.transfer(_receiver, tosend));
  }
  // withdraw DTH when a shop add by admin is delete
  function withdrawDthShopAdmin(address _from, address _receiver) external onlyOwner  {
    require(dthShopBalance[_from]  > 0);
    uint tosend = dthShopBalance[_from];
    dthShopBalance[_from] = 0;
    require(dth.transfer(_receiver, tosend));
  }

  // add DTH when shop register
  function addTokenShop(address _from, uint _value) external onlyOwner {
    dthShopBalance[_from] = SafeMath.add(dthShopBalance[_from], _value);
  }
  // add DTH when token register
  function addTokenTeller(address _from, uint _value) external onlyOwner{
    dthTellerBalance[_from] = SafeMath.add(dthTellerBalance[_from], _value);
  }
  // add ETH for escrow teller
  function addEthTeller(address _from, uint _value) external payable onlyOwner returns (bool) {
    ethTellerBalance[_from] = SafeMath.add(ethTellerBalance[_from] ,_value);
    return true;
  }
  // withdraw ETH for teller escrow
  function withdrawEth(address _from, address _to, uint _amount) external onlyOwner {
    require(ethTellerBalance[_from] >= _amount);
    ethTellerBalance[_from] = SafeMath.sub(ethTellerBalance[_from], _amount);
    _to.transfer(_amount);
  }
  // refund all ETH from teller contract
  function refundEth(address _from) external onlyOwner {
    uint toSend = ethTellerBalance[_from];
    if (toSend > 0) {
      ethTellerBalance[_from] = 0;
      _from.transfer(toSend);
    }
  }

  /**
   * GETTER
   */
  function getDthTeller(address _user) public view returns (uint) {
    return dthTellerBalance[_user];
  }
  function getDthShop(address _user) public view returns (uint) {
    return dthShopBalance[_user];
  }

  function getEthBalTeller(address _user) public view returns (uint) {
    return ethTellerBalance[_user];
  }
  /// @dev Standard ERC223 function that will handle incoming token transfers.
  // DO NOTHING but allow to receive token when addToken* function are called
  // by the dethercore contract
  function tokenFallback(address _from, uint _value, bytes _data) {
    require(msg.sender == address(dth));
  }

}


contract DetherAccessControl {
    // This facet controls access control for Dether. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract.
    //
    //     - The CMO: The CMO is in charge to open or close activity in zone
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn&#39;t have the ability to act in those roles. This
    // restriction is intentional so that we aren&#39;t tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cmoAddress;
    address public csoAddress; // CHIEF SHOP OFFICER
	  mapping (address => bool) public shopModerators;   // centralised moderator, would become decentralised
    mapping (address => bool) public tellerModerators;   // centralised moderator, would become decentralised

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CMO-only functionality
    modifier onlyCMO() {
        require(msg.sender == cmoAddress);
        _;
    }

    function isCSO(address _addr) public view returns (bool) {
      return (_addr == csoAddress);
    }


    modifier isShopModerator(address _user) {
      require(shopModerators[_user]);
      _;
    }
    modifier isTellerModerator(address _user) {
      require(tellerModerators[_user]);
      _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CMO. Only available to the current CEO.
    /// @param _newCMO The address of the new CMO
    function setCMO(address _newCMO) external onlyCEO {
        require(_newCMO != address(0));
        cmoAddress = _newCMO;
    }

    function setCSO(address _newCSO) external onlyCEO {
        require(_newCSO != address(0));
        csoAddress = _newCSO;
    }

    function setShopModerator(address _moderator) external onlyCEO {
      require(_moderator != address(0));
      shopModerators[_moderator] = true;
    }

    function removeShopModerator(address _moderator) external onlyCEO {
      shopModerators[_moderator] = false;
    }

    function setTellerModerator(address _moderator) external onlyCEO {
      require(_moderator != address(0));
      tellerModerators[_moderator] = true;
    }

    function removeTellerModerator(address _moderator) external onlyCEO {
      tellerModerators[_moderator] = false;
    }
    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCEO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CMO account are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}

contract DetherSetup is DetherAccessControl  {

  bool public run1 = false;
  bool public run2 = false;
  // -Need to be whitelisted to be able to register in the contract as a shop or
  // teller, there is two level of identification.
  // -This identification method are now centralised and processed by dether, but
  // will be decentralised soon
  Certifier public smsCertifier;
  Certifier public kycCertifier;
  // Zone need to be open by the CMO before accepting registration
  // The bytes2 parameter wait for a country ID (ex: FR (0x4652 in hex) for france cf:README)
  mapping(bytes2 => bool) public openedCountryShop;
  mapping(bytes2 => bool) public openedCountryTeller;
  // For registering in a zone you need to stake DTH
  // The price can differ by country
  // Uts now a fixed price by the CMO but the price will adjusted automatically
  // regarding different factor in the futur smart contract
  mapping(bytes2 => uint) public licenceShop;
  mapping(bytes2 => uint) public licenceTeller;

  modifier tier1(address _user) {
    require(smsCertifier.certified(_user));
    _;
  }
  modifier tier2(address _user) {
    require(kycCertifier.certified(_user));
    _;
  }
  modifier isZoneShopOpen(bytes2 _country) {
    require(openedCountryShop[_country]);
    _;
  }
  modifier isZoneTellerOpen(bytes2 _country) {
    require(openedCountryTeller[_country]);
    _;
  }

  /**
   * INIT
   */
  function setSmsCertifier (address _smsCertifier) external onlyCEO {
    require(!run1);
    smsCertifier = Certifier(_smsCertifier);
    run1 = true;
  }
  /**
   * CORE FUNCTION
   */
  function setKycCertifier (address _kycCertifier) external onlyCEO {
    require(!run2);
    kycCertifier = Certifier(_kycCertifier);
    run2 = true;
  }
  function setLicenceShopPrice(bytes2 country, uint price) external onlyCMO {
    licenceShop[country] = price;
  }
  function setLicenceTellerPrice(bytes2 country, uint price) external onlyCMO {
    licenceTeller[country] = price;
  }
  function openZoneShop(bytes2 _country) external onlyCMO {
    openedCountryShop[_country] = true;
  }
  function closeZoneShop(bytes2 _country) external onlyCMO {
    openedCountryShop[_country] = false;
  }
  function openZoneTeller(bytes2 _country) external onlyCMO {
    openedCountryTeller[_country] = true;
  }
  function closeZoneTeller(bytes2 _country) external onlyCMO {
    openedCountryTeller[_country] = false;
  }
}



library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don&#39;t need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let&#39;s prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don&#39;t care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we&#39;re done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin&#39;s length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let&#39;s just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function toBytes16(bytes _bytes, uint _start) internal  pure returns (bytes16) {
        require(_bytes.length >= (_start + 16));
        bytes16 tempBytes16;

        assembly {
            tempBytes16 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes16;
    }

    function toBytes2(bytes _bytes, uint _start) internal  pure returns (bytes2) {
        require(_bytes.length >= (_start + 2));
        bytes2 tempBytes2;

        assembly {
            tempBytes2 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes2;
    }

    function toBytes4(bytes _bytes, uint _start) internal  pure returns (bytes4) {
        require(_bytes.length >= (_start + 4));
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }
        return tempBytes4;
    }

    function toBytes1(bytes _bytes, uint _start) internal  pure returns (bytes1) {
        require(_bytes.length >= (_start + 1));
        bytes1 tempBytes1;

        assembly {
            tempBytes1 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes1;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there&#39;s
                //  no said feature for inline assembly loops
                // cb = 1 - don&#39;t breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let&#39;s prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there&#39;s
                        //  no said feature for inline assembly loops
                        // cb = 1 - don&#39;t breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}


contract DetherCore is DetherSetup, ERC223ReceivingContract, SafeMath {
  using BytesLib for bytes;

  /**
  * Event
  */
  // when a Teller is registered
  event RegisterTeller(address indexed tellerAddress);
  // when a teller is deleted
  event DeleteTeller(address indexed tellerAddress);
  // when teller update
  event UpdateTeller(address indexed tellerAddress);
  // when a teller send to a buyer
  event Sent(address indexed _from, address indexed _to, uint amount);
  // when a shop register
  event RegisterShop(address shopAddress);
  // when a shop delete
  event DeleteShop(address shopAddress);
  // when a moderator delete a shop
  event DeleteShopModerator(address indexed moderator, address shopAddress);
  // when a moderator delete a teller
  event DeleteTellerModerator(address indexed moderator, address tellerAddress);

  /**
   * Modifier
   */
  // if teller has staked enough dth to
  modifier tellerHasStaked(uint amount) {
    require(bank.getDthTeller(msg.sender) >= amount);
    _;
  }
  // if shop has staked enough dth to
  modifier shopHasStaked(uint amount) {
    require(bank.getDthShop(msg.sender) >= amount);
    _;
  }

  /*
   * External contract
   */
  // DTH contract
  ERC223Basic public dth;
  // bank contract where are stored ETH and DTH
  DetherBank public bank;

  // teller struct
  struct Teller {
    int32 lat;            // Latitude
    int32 lng;            // Longitude
    bytes2 countryId;     // countryID (in hexa), ISO ALPHA 2 https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    bytes16 postalCode;   // postalCode if present, in Hexa https://en.wikipedia.org/wiki/List_of_postal_codes

    int8 currencyId;      // 1 - 100 , cf README
    bytes16 messenger;    // telegrame nickname
    int8 avatarId;        // 1 - 100 , regarding the front-end app you use
    int16 rates;          // margin of tellers , -999 - +9999 , corresponding to -99,9% x 10  , 999,9% x 10

    uint zoneIndex;       // index of the zone mapping
    uint generalIndex;    // index of general mapping
    bool online;          // switch online/offline, if the tellers want to be inactive without deleting his point
  }

  /*
   * Reputation field V0.1
   * Reputation is based on volume sell, volume buy, and number of transaction
   */
  mapping(address => uint) volumeBuy;
  mapping(address => uint) volumeSell;
  mapping(address => uint) nbTrade;

  // general mapping of teller
  mapping(address => Teller) teller;
  // mappoing of teller by COUNTRYCODE => POSTALCODE
  mapping(bytes2 => mapping(bytes16 => address[])) tellerInZone;
  // teller array currently registered
  address[] public tellerIndex; // unordered list of teller register on it
  bool isStarted = false;
  // shop struct
  struct Shop {
    int32 lat;            // latitude
    int32 lng;            // longitude
    bytes2 countryId;     // countryID (in hexa char), ISO ALPHA 2 https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    bytes16 postalCode;   // postalCode if present (in hexa char), in Hexa https://en.wikipedia.org/wiki/List_of_postal_codes
    bytes16 cat;          // Category of the shop (in hex char), will be used later for search engine and auction by zone
    bytes16 name;         // name of the shop (in hex char)
    bytes32 description;  // description of the shop
    bytes16 opening;      // opening hours, cf README for the format

    uint zoneIndex;       // index of the zone mapping
    uint generalIndex;    // index of general mapping
    bool detherShop;      // bool if shop is registered by dether as business partnership (still required DTH)
  }

  // general mapping of shop
  mapping(address => Shop) shop;
  // mapping of teller by COUNTRYCODE => POSTALCODE
  mapping(bytes2 => mapping(bytes16 => address[])) shopInZone;
  // shop array currently registered
  address[] public shopIndex; // unordered list of shop register on it

  /*
   * Instanciation
   */
  function DetherCore() {
   ceoAddress = msg.sender;
  }
  function initContract (address _dth, address _bank) external onlyCEO {
    require(!isStarted);
    dth = ERC223Basic(_dth);
    bank = DetherBank(_bank);
    isStarted = true;
  }

  /**
   * Core fonction
   */

  /**
   * @dev Standard ERC223 function that will handle incoming token transfers.
   * This is the main function to register SHOP or TELLER, its calling when you
   * send token to the DTH contract and by passing data as bytes on the third
   * parameter.
   * Its not supposed to be use on its own but will only handle incoming DTH
   * transaction.
   * The _data will wait for
   * [1st byte] 1 (0x31) for shop OR 2 (0x32) for teller
   * FOR SHOP AND TELLER:
   * 2sd to 5th bytes lat
   * 6th to 9th bytes lng
   * ...
   * Modifier tier1: Check if address is whitelisted with the sms verification
   */
  function tokenFallback(address _from, uint _value, bytes _data) whenNotPaused tier1(_from ) {
    // require than the token fallback is triggered from the dth token contract
    require(msg.sender == address(dth));
    // check first byte to know if its shop or teller registration
    // 1 / 0x31 = shop // 2 / 0x32 = teller
    bytes1 _func = _data.toBytes1(0);
    int32 posLat = _data.toBytes1(1) == bytes1(0x01) ? int32(_data.toBytes4(2)) * -1 : int32(_data.toBytes4(2));
    int32 posLng = _data.toBytes1(6) == bytes1(0x01) ? int32(_data.toBytes4(7)) * -1 : int32(_data.toBytes4(7));
    if (_func == bytes1(0x31)) { // shop registration
      // require staked greater than licence price
      require(_value >= licenceShop[_data.toBytes2(11)]);
      // require its not already shop
      require(!isShop(_from));
      // require zone is open
      require(openedCountryShop[_data.toBytes2(11)]);

      shop[_from].lat = posLat;
      shop[_from].lng = posLng;
      shop[_from].countryId = _data.toBytes2(11);
      shop[_from].postalCode = _data.toBytes16(13);
      shop[_from].cat = _data.toBytes16(29);
      shop[_from].name = _data.toBytes16(45);
      shop[_from].description = _data.toBytes32(61);
      shop[_from].opening = _data.toBytes16(93);
      shop[_from].generalIndex = shopIndex.push(_from) - 1;
      shop[_from].zoneIndex = shopInZone[_data.toBytes2(11)][_data.toBytes16(13)].push(_from) - 1;
      emit RegisterShop(_from);
      bank.addTokenShop(_from,_value);
      dth.transfer(address(bank), _value);
    } else if (_func == bytes1(0x32)) { // teller registration
      // require staked greater than licence price
      require(_value >= licenceTeller[_data.toBytes2(11)]);
      // require is not already a teller
      require(!isTeller(_from));
      // require zone is open
      require(openedCountryTeller[_data.toBytes2(11)]);

      teller[_from].lat = posLat;
      teller[_from].lng = posLng;
      teller[_from].countryId = _data.toBytes2(11);
      teller[_from].postalCode = _data.toBytes16(13);
      teller[_from].avatarId = int8(_data.toBytes1(29));
      teller[_from].currencyId = int8(_data.toBytes1(30));
      teller[_from].messenger = _data.toBytes16(31);
      teller[_from].rates = int16(_data.toBytes2(47));
      teller[_from].generalIndex = tellerIndex.push(_from) - 1;
      teller[_from].zoneIndex = tellerInZone[_data.toBytes2(11)][_data.toBytes16(13)].push(_from) - 1;
      teller[_from].online = true;
      emit RegisterTeller(_from);
      bank.addTokenTeller(_from, _value);
      dth.transfer(address(bank), _value);
    } else if (_func == bytes1(0x33)) {  // shop bulk registration
      // We need to have the possibility to register in bulk some shop
      // For big retailer company willing to be listed on dether, we need to have a way to add
      // all their shop from one address
      // This functionnality will become available for anyone willing to list multiple shop
      // in the futures contract

      // Only the CSO should be able to register shop in bulk
      require(_from == csoAddress);
      // Each shop still need his own staking
      require(_value >= licenceShop[_data.toBytes2(11)]);
      // require the addresses not already registered
      require(!isShop(address(_data.toAddress(109))));
      // require zone is open
      require(openedCountryShop[_data.toBytes2(11)]);
      address newShopAddress = _data.toAddress(109);
      shop[newShopAddress].lat = posLat;
      shop[newShopAddress].lng = posLng;
      shop[newShopAddress].countryId = _data.toBytes2(11);
      shop[newShopAddress].postalCode = _data.toBytes16(13);
      shop[newShopAddress].cat = _data.toBytes16(29);
      shop[newShopAddress].name = _data.toBytes16(45);
      shop[newShopAddress].description = _data.toBytes32(61);
      shop[newShopAddress].opening = _data.toBytes16(93);
      shop[newShopAddress].generalIndex = shopIndex.push(newShopAddress) - 1;
      shop[newShopAddress].zoneIndex = shopInZone[_data.toBytes2(11)][_data.toBytes16(13)].push(newShopAddress) - 1;
      shop[newShopAddress].detherShop = true;
      emit RegisterShop(newShopAddress);
      bank.addTokenShop(newShopAddress, _value);
      dth.transfer(address(bank), _value);
    }
  }

  /**
   * a teller can update his profile
   * If a teller want to change his location, he would need to delete and recreate
   * a new point
   */
  function updateTeller(
    int8 currencyId,
    bytes16 messenger,
    int8 avatarId,
    int16 rates,
    bool online
   ) public payable {
    require(isTeller(msg.sender));
    if (currencyId != teller[msg.sender].currencyId)
    teller[msg.sender].currencyId = currencyId;
    if (teller[msg.sender].messenger != messenger)
     teller[msg.sender].messenger = messenger;
    if (teller[msg.sender].avatarId != avatarId)
     teller[msg.sender].avatarId = avatarId;
    if (teller[msg.sender].rates != rates)
     teller[msg.sender].rates = rates;
    if (teller[msg.sender].online != online)
      teller[msg.sender].online = online;
    if (msg.value > 0) {
      bank.addEthTeller.value(msg.value)(msg.sender, msg.value);
    }
    emit UpdateTeller(msg.sender);
  }

  /**
   * SellEth
   * @param _to -> the address for the receiver
   * @param _amount -> the amount to send
   */
  function sellEth(address _to, uint _amount) whenNotPaused external {
    require(isTeller(msg.sender));
    require(_to != msg.sender);
    // send eth to the receiver from the bank contract
    bank.withdrawEth(msg.sender, _to, _amount);
    // increase reput for the buyer and the seller Only if the buyer is also whitelisted,
    // It&#39;s a way to incentive user to trade on the system
    if (smsCertifier.certified(_to)) {
      volumeBuy[_to] = SafeMath.add(volumeBuy[_to], _amount);
      volumeSell[msg.sender] = SafeMath.add(volumeSell[msg.sender], _amount);
      nbTrade[msg.sender] += 1;
    }
    emit Sent(msg.sender, _to, _amount);
  }

  /**
   * switchStatus
   * Turn status teller on/off
   */
  function switchStatus(bool _status) external {
    if (teller[msg.sender].online != _status)
     teller[msg.sender].online = _status;
  }

  /**
   * addFunds
   * teller can add more funds on his sellpoint
   */
  function addFunds() external payable {
    require(isTeller(msg.sender));
    require(bank.addEthTeller.value(msg.value)(msg.sender, msg.value));
  }

  // gas used 67841
  // a teller can delete a sellpoint
  function deleteTeller() external {
    require(isTeller(msg.sender));
    uint rowToDelete1 = teller[msg.sender].zoneIndex;
    address keyToMove1 = tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode][tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode].length - 1];
    tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode][rowToDelete1] = keyToMove1;
    teller[keyToMove1].zoneIndex = rowToDelete1;
    tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode].length--;

    uint rowToDelete2 = teller[msg.sender].generalIndex;
    address keyToMove2 = tellerIndex[tellerIndex.length - 1];
    tellerIndex[rowToDelete2] = keyToMove2;
    teller[keyToMove2].generalIndex = rowToDelete2;
    tellerIndex.length--;
    delete teller[msg.sender];
    bank.withdrawDthTeller(msg.sender);
    bank.refundEth(msg.sender);
    emit DeleteTeller(msg.sender);
  }

  // gas used 67841
  // A moderator can delete a sellpoint
  function deleteTellerMods(address _toDelete) isTellerModerator(msg.sender) external {
    uint rowToDelete1 = teller[_toDelete].zoneIndex;
    address keyToMove1 = tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode][tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode].length - 1];
    tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode][rowToDelete1] = keyToMove1;
    teller[keyToMove1].zoneIndex = rowToDelete1;
    tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode].length--;

    uint rowToDelete2 = teller[_toDelete].generalIndex;
    address keyToMove2 = tellerIndex[tellerIndex.length - 1];
    tellerIndex[rowToDelete2] = keyToMove2;
    teller[keyToMove2].generalIndex = rowToDelete2;
    tellerIndex.length--;
    delete teller[_toDelete];
    bank.withdrawDthTeller(_toDelete);
    bank.refundEth(_toDelete);
    emit DeleteTellerModerator(msg.sender, _toDelete);
  }

  // gas used 67841
  // A shop owner can delete his point.
  function deleteShop() external {
    require(isShop(msg.sender));
    uint rowToDelete1 = shop[msg.sender].zoneIndex;
    address keyToMove1 = shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode][shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode].length - 1];
    shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode][rowToDelete1] = keyToMove1;
    shop[keyToMove1].zoneIndex = rowToDelete1;
    shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode].length--;

    uint rowToDelete2 = shop[msg.sender].generalIndex;
    address keyToMove2 = shopIndex[shopIndex.length - 1];
    shopIndex[rowToDelete2] = keyToMove2;
    shop[keyToMove2].generalIndex = rowToDelete2;
    shopIndex.length--;
    delete shop[msg.sender];
    bank.withdrawDthShop(msg.sender);
    emit DeleteShop(msg.sender);
  }

  // gas used 67841
  // Moderator can delete a shop point
  function deleteShopMods(address _toDelete) isShopModerator(msg.sender) external {
    uint rowToDelete1 = shop[_toDelete].zoneIndex;
    address keyToMove1 = shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode][shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode].length - 1];
    shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode][rowToDelete1] = keyToMove1;
    shop[keyToMove1].zoneIndex = rowToDelete1;
    shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode].length--;

    uint rowToDelete2 = shop[_toDelete].generalIndex;
    address keyToMove2 = shopIndex[shopIndex.length - 1];
    shopIndex[rowToDelete2] = keyToMove2;
    shop[keyToMove2].generalIndex = rowToDelete2;
    shopIndex.length--;
    if (!shop[_toDelete].detherShop)
      bank.withdrawDthShop(_toDelete);
    else
      bank.withdrawDthShopAdmin(_toDelete, csoAddress);
    delete shop[_toDelete];
    emit DeleteShopModerator(msg.sender, _toDelete);
  }

  /**
   *  GETTER
   */

  // get teller
  // return teller info
  function getTeller(address _teller) public view returns (
    int32 lat,
    int32 lng,
    bytes2 countryId,
    bytes16 postalCode,
    int8 currencyId,
    bytes16 messenger,
    int8 avatarId,
    int16 rates,
    uint balance,
    bool online,
    uint sellVolume,
    uint numTrade
    ) {
    Teller storage theTeller = teller[_teller];
    lat = theTeller.lat;
    lng = theTeller.lng;
    countryId = theTeller.countryId;
    postalCode = theTeller.postalCode;
    currencyId = theTeller.currencyId;
    messenger = theTeller.messenger;
    avatarId = theTeller.avatarId;
    rates = theTeller.rates;
    online = theTeller.online;
    sellVolume = volumeSell[_teller];
    numTrade = nbTrade[_teller];
    balance = bank.getEthBalTeller(_teller);
  }

  /*
   * Shop ----------------------------------
   * return Shop value
   */
  function getShop(address _shop) public view returns (
   int32 lat,
   int32 lng,
   bytes2 countryId,
   bytes16 postalCode,
   bytes16 cat,
   bytes16 name,
   bytes32 description,
   bytes16 opening
   ) {
    Shop storage theShop = shop[_shop];
    lat = theShop.lat;
    lng = theShop.lng;
    countryId = theShop.countryId;
    postalCode = theShop.postalCode;
    cat = theShop.cat;
    name = theShop.name;
    description = theShop.description;
    opening = theShop.opening;
   }

   // get reput
   // return reputation data from teller
  function getReput(address _teller) public view returns (
   uint buyVolume,
   uint sellVolume,
   uint numTrade
   ) {
     buyVolume = volumeBuy[_teller];
     sellVolume = volumeSell[_teller];
     numTrade = nbTrade[_teller];
  }
  // return balance of teller put in escrow
  function getTellerBalance(address _teller) public view returns (uint) {
    return bank.getEthBalTeller(_teller);
  }

  // return an array of address of all zone present on a zone
  // zone is a mapping COUNTRY => POSTALCODE
  function getZoneShop(bytes2 _country, bytes16 _postalcode) public view returns (address[]) {
     return shopInZone[_country][_postalcode];
  }

  // return array of address of all shop
  function getAllShops() public view returns (address[]) {
   return shopIndex;
  }

  function isShop(address _shop) public view returns (bool ){
   return (shop[_shop].countryId != bytes2(0x0));
  }

  // return an array of address of all teller present on a zone
  // zone is a mapping COUNTRY => POSTALCODE
  function getZoneTeller(bytes2 _country, bytes16 _postalcode) public view returns (address[]) {
     return tellerInZone[_country][_postalcode];
  }

  // return array of address of all teller
  function getAllTellers() public view returns (address[]) {
   return tellerIndex;
  }

  // return if teller or not
  function isTeller(address _teller) public view returns (bool ){
    return (teller[_teller].countryId != bytes2(0x0));
  }

  /*
   * misc
   */
   // return info about how much DTH the shop has staked
  function getStakedShop(address _shop) public view returns (uint) {
    return bank.getDthShop(_shop);
  }
  // return info about how much DTH the teller has staked
  function getStakedTeller(address _teller) public view returns (uint) {
    return bank.getDthTeller(_teller);
  }
  // give ownership to the bank contract
  function transferBankOwnership(address _newbankowner) external onlyCEO whenPaused {
    bank.transferOwnership(_newbankowner);
  }
}