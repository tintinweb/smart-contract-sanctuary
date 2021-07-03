/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * @dev This emits when ownership of a contract changes.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Set the address of the new owner of the contract
     * @param newOwner The address of the new owner of the contract
     */
    function transferOwnership(address newOwner) external;
}


// File @beandao/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IMulticall {
    function multicall(bytes[] calldata callData)
        external
        returns (bytes[] memory returnData);
}


// File @beandao/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IAllowlist {
    event Allowed(address addr);
    event Revoked(address addr);

    function allowance(address) external returns (bool);

    function authorise(address allowAddr) external;

    function revoke(address revokeAddr) external;
}


// File @beandao/contracts/library/[email protected]

pragma solidity ^0.8.0;

contract Ownership is IERC173 {
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownership/Not-Authorized");
        _;
    }

    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner)
        external
        override
        onlyOwner
    {
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}


// File @beandao/contracts/library/[email protected]

pragma solidity ^0.8.0;

contract Create2Maker {
    constructor(address template, bytes memory initializationCalldata)
        payable
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = template.delegatecall(initializationCalldata);
        if (!success) {
            // pass along failure message from delegatecall and revert.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place eip-1167 runtime code in memory.
        bytes memory runtimeCode =
            abi.encodePacked(
                bytes10(0x363d3d373d3d3d363d73),
                template,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );

        // return eip-1167 code to write it to spawned contract runtime.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
        }
    }
}


// File @beandao/contracts/library/[email protected]

pragma solidity ^0.8.0;

library Deployer {
    function deploy(address template, bytes memory initializationCalldata)
        internal
        returns (address result)
    {
        bytes memory createCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(template), initializationCalldata)
            );

        (bytes32 salt, ) = getSaltAndTarget(createCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function deployWithValue(
        address template,
        bytes memory initializationCalldata
    ) internal returns (address result) {
        bytes memory createCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(template), initializationCalldata)
            );

        (bytes32 salt, ) = getSaltAndTarget(createCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                callvalue(), // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function calculateAddress(
        address template,
        bytes memory initializationCalldata
    ) internal view returns (address addr) {
        bytes memory createCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(template), initializationCalldata)
            );

        (, addr) = getSaltAndTarget(createCode);
    }

    function getSaltAndTarget(bytes memory initCode)
        internal
        view
        returns (bytes32 salt, address target)
    {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        // set the initial nonce to be provided when constructing the salt.
        uint256 nonce = 0;

        // declare variable for code size of derived address.
        bool exist;

        while (true) {
            // derive `CREATE2` salt using `msg.sender` and nonce.
            salt = keccak256(abi.encodePacked(msg.sender, nonce));

            target = address( // derive the target deployment address.
                uint160( // downcast to match the address type.
                    uint256( // cast to uint to truncate upper digits.
                        keccak256( // compute CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                bytes1(0xff), // pass in the control character.
                                address(this), // pass in the address of this contract.
                                salt, // pass in the salt from above.
                                initCodeHash // pass in hash of contract creation code.
                            )
                        )
                    )
                )
            );

            // determine if a contract is already deployed to the target address.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            // exit the loop if no contract is deployed to the target address.
            if (!exist) {
                break;
            }

            // otherwise, increment the nonce and derive a new salt.
            nonce++;
        }
    }
}


// File contracts/IFactory.sol

pragma solidity ^0.8.0;

interface IFactory {
    struct Template {
        address template;
        address owner;
        uint256 price;
    }

    function deploy(
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed);

    function calculateDeployableAddress(
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable);

    function getPrice(bytes32 templateId) external view returns (uint256 price);

    event Deployed(address deployed, address owner);
    event NewTemplate(
        bytes32 indexed key,
        address indexed template,
        uint256 price
    );
    event UpdatedTemplate(
        bytes32 indexed key,
        address indexed template,
        uint256 price
    );
}


// File contracts/FactoryV1.sol

pragma solidity ^0.8.0;






/**
 * @title Factory V1
 * @author yoonsung.eth
 * @notice minimal proxy로 배포될 컨트랙트를 template로 추상화 하며 같은 컨트랙트를 쉽게 배포할 수 있도록 함.
 * @dev template에는 단 한번만 호출 가능한 initialize 함수가 필요하며, 이는 필수적으로 호출되어야 함.
 * ERC173이 구현되어 컨트랙트의 소유권을 옮길 수 있도록 하여야 함.
 */
contract FactoryV1 is Ownership, IFactory {
    struct Entity {
        bytes32 _key;
        Template _value;
    }

    Entity[] public entities;
    mapping(bytes32 => uint256) public indexes;
    /**
     * @notice template가 총 얼마나 사용되었는지 나타내는 값.
     */
    mapping(bytes32 => uint256) public nonces;

    IAllowlist private immutable allowlist;

    // 30 / 10000 = 0.3 %
    uint256 public constant FEE_RATE = 30;

    /**
     * @notice 허용 목록 컨트랙트가 미리 배포되어 주입 되어야 한다.
     * @param allowContract IAllowlist를 구현한 컨트랙트 주소
     */
    constructor(address allowContract) {
        Ownership.initialize(msg.sender);
        allowlist = IAllowlist(allowContract);
    }

    /**
     * @notice template id를 통해서 해당 컨트랙트를 배포하는 함수, 여기에는 initialize 함수를 한 번 호출할 수 있도록 call data가 필요함.
     * @dev deploy에서 기본적으로 오너십을 체크하지는 않기 때문에, 오너십 관리가 필요한 경우 multicall을 통해서 필수적으로 호출해 주어야 함.
     * @param templateId bytes32 형태의 template id가 필요
     * @param initializationCallData 템플릿에 적합한 initialize 함수를 호출하는 함수 데이터
     * @param calls 컨트랙트가 배포된 이후에, 부수적으로 초기화 할 함수들이 있을 때 사용 가능함.
     */
    function deploy(
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable override returns (address deployed) {
        // 배포할 템플릿의 정보
        Template memory tmp = _get(templateId);
        // 템플릿을 배포하기 위한 수수료가 적정 수준인지, 템플릿 오너가 호출한 것인지 또는 호출자가 허용된 목록에 있는지 확인.
        require(
            tmp.price == msg.value ||
                tmp.owner == msg.sender ||
                allowlist.allowance(msg.sender),
            "Factory/Incorrect-amounts"
        );
        // 지정된 정보로 컨트랙트를 배포함.
        deployed = Deployer.deploy(tmp.template, initializationCallData);
        // 부수적으로 호출할 데이터가 있다면, 배포된 컨트랙트에 추가적인 call을 할 수 있음.
        if (calls.length > 0) IMulticall(deployed).multicall(calls);
        // 해당 함수를 호출할 때 수수료가 담긴 경우에 수수료를 컨트랙트 소유자에게 전송하고 기존 수수료에서 일정 비율 만큼 수수료를 상승 시킴
        if (msg.value > 0) {
            payable(this.owner()).transfer(msg.value);
            tmp.price += ((tmp.price / 10000) * FEE_RATE);
            _set(templateId, tmp);
        }
        // 이벤트 호출
        emit Deployed(deployed, msg.sender);
    }

    /**
     * @notice template id를 통해서 컨트랙트를 배포할 주소를 미리 파악하는 함수
     * @param templateId bytes32 형태의 template id가 필요
     * @param initializationCallData 템플릿에 적합한 initialize 함수를 호출하는 함수 데이터
     */
    function calculateDeployableAddress(
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view override returns (address deployable) {
        Template memory tmp = _get(templateId);
        deployable = Deployer.calculateAddress(
            tmp.template,
            initializationCallData
        );
    }

    /**
     * @notice template id에 따라서 컨트랙트를 배포하기 위한 필요 가격을 가져오는 함수
     * @param templateId 값을 가져올 템플릿의 아이디
     * @return price 이더리움으로 구성된 값을 가짐.
     */
    function getPrice(bytes32 templateId)
        external
        view
        override
        returns (uint256 price)
    {
        price = _get(templateId).price;
    }

    /**
     * @notice 템플릿으로 사용되기 적합한 인터페이스가 구현된 컨트랙트를 템플릿으로 가격과 함께 등록함.
     * @param templateAddr 템플릿으로 사용될 컨트랙트의 주소
     * @param ownerAddr 해당 템플릿의 소유주를 지정함. 해당 소유주는 수수료를 지불하지 않음.
     * @param price 템플릿으로 컨트랙트를 배포할 때 소모될 이더리움의 수량
     */
    function addTemplate(
        address templateAddr,
        address ownerAddr,
        uint256 price
    ) external onlyOwner returns (bool success) {
        require(templateAddr != address(0), "Factory/Template-Address-is-Zero");
        Entity[] memory _entities = entities;
        for (uint256 i = 0; i < entities.length; i++) {
            require(
                _entities[i]._value.template != templateAddr,
                "Factory/Exist-Template"
            );
        }
        bytes32 key = keccak256(abi.encode(templateAddr, _entities.length));
        Template memory tmp = Template({
            template: templateAddr,
            owner: ownerAddr,
            price: price
        });

        _set(key, tmp);
        success = true;
        emit NewTemplate(key, templateAddr, price);
    }

    /**
     * @notice 등록된 템플릿의 정보를 변경하는 함수
     * @param key 업데이트 될 템플릿의 아이디
     * @param updateCode 템플릿 컨트랙트 주소, 템플릿 소유주 주소, 가격을 순서대로 인코딩
     * @return success 성공하였다면 true를 반환함
     */
    function updateTemplate(bytes32 key, bytes memory updateCode)
        external
        onlyOwner
        returns (bool success)
    {
        Template memory tmp = _get(key);
        (address templateAddr, address ownerAddr, uint256 price) = abi.decode(
            updateCode,
            (address, address, uint256)
        );
        tmp.template = (templateAddr != address(0) &&
            templateAddr != tmp.template)
            ? templateAddr
            : tmp.template;
        tmp.owner = (ownerAddr != tmp.owner) ? ownerAddr : tmp.owner;
        tmp.price = price != 0 ? price : tmp.price;

        _set(key, tmp);
        success = true;
        emit UpdatedTemplate(key, tmp.template, tmp.price);
    }

    /**
     * @notice 등록된 템플릿을 삭제하는 함수
     * @param key 삭제될 템플릿의 아이디
     * @return success 성공하였다면 true를 반환함
     */
    function removeTemplate(bytes32 key)
        external
        onlyOwner
        returns (bool success)
    {
        require(
            (success = _remove(key)) && success,
            "Factory/None-Exist-Template"
        );
    }

    function _set(bytes32 key, Template memory tmp) internal {
        uint256 keyIndex = indexes[key];

        if (keyIndex == 0) {
            entities.push(Entity({_key: key, _value: tmp}));
            indexes[key] = entities.length;
        } else {
            entities[keyIndex - 1]._value = tmp;
        }
    }

    function _get(bytes32 key) private view returns (Template memory) {
        uint256 keyIndex = indexes[key];
        require(keyIndex != 0, "Factory/None-Exist"); // Equivalent to contains(map, key)
        return entities[keyIndex - 1]._value; // All indexes are 1-based
    }

    function _remove(bytes32 key) private returns (bool success) {
        uint256 keyIndex = indexes[key];

        if (keyIndex != 0) {
            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = entities.length - 1;

            Entity storage lastEntity = entities[lastIndex];

            entities[toDeleteIndex] = lastEntity;
            indexes[lastEntity._key] = toDeleteIndex + 1;

            entities.pop();

            delete indexes[key];
            success = true;
        } else {
            success = false;
        }
    }
}