/* ERC223 token
   Copyright (C) 2017  Sergey Sherkunov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="adc1c8c4c3c1ccdad8c3edc1c8c4c3c1ccdad8c383c2dfca">[email&#160;protected]</a>>

   This file is part of ERC223 token.

   Token is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

pragma solidity ^0.4.24;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;

        assert(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assert(b <= a);

        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;

        assert(c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a / b;
    }
}

contract ERC223Storage {
    enum TernarySwitch {
        Undefined,
        Disabled,
        Enabled
    }

    address public owner;

    address public pendingOwner;

    address public minter;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    //For backward compatibility with ERC20.
    mapping(address => mapping(address => uint256)) public allowance;

    bool public privilegedTransferLocked;

    bool public privilegedMintLocked;

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break.
    mapping(address => TernarySwitch) public forceExecuteOf;

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break.
    bool public forceExecuteOfContracts;

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break.
    bool public forceExecuteOfUsers;

    modifier onlyOwner {
        require(msg.sender == owner);

        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner && pendingOwner != 0x0);

        _;
    }
}

contract ERC223Proxy is ERC223Storage {
    address public implementation;

    event Upgrade(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    constructor(address initialImplementation) public {
        owner = msg.sender;

        uncheckedUpgrade(initialImplementation);
    }

    function transferOwnership(address newOwner)
        public onlyOwner returns(bool) {
        pendingOwner = newOwner;

        return true;
    }

    function claimOwnership() public onlyPendingOwner returns(bool) {
        owner = pendingOwner;

        return true;
    }

    function upgrade(address newImplementation) public onlyOwner {
        uncheckedUpgrade(newImplementation);
    }

    function () external payable {
        bytes memory data = msg.data;

        assembly {
            let result := delegatecall(
                gas,
                implementation_slot,
                add(data, 0x20),
                mload(data),
                0x0,
                0x0
            )
            let returnDataSize := returndatasize
            let returnData := mload(0x40)

            returndatacopy(returnData, 0x0, returnDataSize)

            switch result
                case 0 { revert(returnData, returnDataSize) }
                default { return(returnData, returnDataSize) }
        }
    }

    function uncheckedUpgrade(address newImplementation) private {
        implementation = newImplementation;

        emit Upgrade(implementation, newImplementation);
    }
}

interface ERC223Receiver {
    function tokenFallback(
        address oldTokensHolder,
        uint256 tokensNumber,
        bytes data
    ) external;
}

contract ERC223Token is ERC223Storage, ERC223Receiver {
    using SafeMath for uint256;

    //For backward compatibility with ERC20.
    event Transfer(
        address indexed oldTokensHolder,
        address indexed newTokensHolder,
        uint256 tokensNumber
    );

    //For backward compatibility with ERC20.
    //
    //An Attack Vector on Approve/TransferFrom Methods:
    //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    event Transfer(
        address indexed tokensSpender,
        address indexed oldTokensHolder,
        address indexed newTokensHolder,
        uint256 tokensNumber
    );

    event Transfer(
        address indexed oldTokensHolder,
        address indexed newTokensHolder,
        uint256 indexed tokensNumber,
        bytes data
    );

    //For backward compatibility with ERC20.
    event Approval(
        address indexed tokensHolder,
        address indexed tokensSpender,
        uint256 newTokensNumber
    );

    //For backward compatibility with ERC20.
    //
    //An Attack Vector on Approve/TransferFrom Methods:
    //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    event Approval(
        address indexed tokensHolder,
        address indexed tokensSpender,
        uint256 oldTokensNumber,
        uint256 newTokensNumber
    );

    event Mint(uint256 indexed tokensNumber);

    event Burn(address indexed oldTokensHolder, uint256 indexed tokensNumber);

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break.
    event BadWay();

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break.
    event PossibleLossTokens();

    modifier onlyPrivileged {
        require(msg.sender == owner || msg.sender == minter);

        _;
    }

    modifier onlyPrivilegedTransferNotLocked {
        require(!privilegedTransferLocked);

        _;
    }

    modifier onlyPrivilegedTransferLocked {
        require(privilegedTransferLocked);

        _;
    }

    modifier onlyPrivilegedMintNotLocked {
        require(!privilegedMintLocked);

        _;
    }

    modifier onlyThisToken {
        require(this == msg.sender);

        _;
    }

    modifier onlyEmptyData(bytes data) {
        require(data.length == 0);

        _;
    }

    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    modifier checkPayloadSize(uint256 size) {
       require(msg.data.length == size + 4);

       _;
    }

    function initialize(
        address initialMinter,
        string initialName,
        string initialSymbol,
        uint8 initialDecimals,
        uint256 initialTotalSupply,
        bool initialPrivilegedMintLocked,
        //For backward compatibility with ERC20.
        //
        //It is necessary to support a vulnerability in ERC20, without which
        //something can break.
        bool initialForceExecuteOfContracts,
        //For backward compatibility with ERC20.
        //
        //It is necessary to support a vulnerability in ERC20, without which
        //something can break.
        bool initialForceExecuteOfUsers
    ) public onlyOwner {
        name = initialName;

        symbol = initialSymbol;

        decimals = initialDecimals;

        //For backward compatibility with ERC20.
        //
        //It is necessary to support a vulnerability in ERC20, without which
        //something can break.
        forceExecuteOfContracts = initialForceExecuteOfContracts;

        //For backward compatibility with ERC20.
        //
        //It is necessary to support a vulnerability in ERC20, without which
        //something can break.
        forceExecuteOfUsers = initialForceExecuteOfUsers;

        require(setMinter(owner));

        require(mint(initialTotalSupply));

        require(setMinter(initialMinter));

        privilegedMintLocked = initialPrivilegedMintLocked;
    }

    function setMinter(address newMinter) public onlyOwner returns(bool) {
        minter = newMinter;

        return true;
    }

    function privilegedTransferLock() public onlyOwner returns(bool) {
        require(privilegedMintLock());

        privilegedTransferLocked = true;

        return true;
    }

    function privilegedMintLock() public onlyOwner returns(bool) {
        privilegedMintLocked = true;

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    function setForceExecute(TernarySwitch state) public returns(bool) {
        forceExecuteOf[msg.sender] = state;

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    function setForceExecuteOfToken(TernarySwitch state)
        public onlyOwner returns(bool) {
        forceExecuteOf[this] = state;

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    function setForceExecuteOfContracts(bool enabled)
        public onlyOwner returns(bool) {
        forceExecuteOfContracts = enabled;

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break. In the bright future, when everyone will support
    //ERC223, it needs to be burned with napalm.
    function setForceExecuteOfUsers(bool enabled)
        public onlyOwner returns(bool) {
        forceExecuteOfUsers = enabled;

        return true;
    }

    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function transfer(address newTokensHolder, uint256 tokensNumber)
        public checkPayloadSize(2 * 32) returns(bool) {
        bytes memory emptyData;
        string memory emptyCustomFallback;

        transfer(
            msg.sender,
            newTokensHolder,
            tokensNumber,
            emptyData,
            emptyCustomFallback,
            false
        );

        return true;
    }

    function transfer(address newTokensHolder, uint256 tokensNumber, bytes data)
        public returns(bool) {
        string memory emptyCustomFallback;

        transfer(
            msg.sender,
            newTokensHolder,
            tokensNumber,
            data,
            emptyCustomFallback,
            false
        );

        return true;
    }

    function transfer(
        address newTokensHolder,
        uint256 tokensNumber,
        bytes data,
        string customFallback
    ) public returns(bool) {
        transfer(
            msg.sender,
            newTokensHolder,
            tokensNumber,
            data,
            customFallback,
            false
        );

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function transferFrom(
        address oldTokensHolder,
        address newTokensHolder,
        uint256 tokensNumber
    ) public checkPayloadSize(3 * 32) returns (bool) {
        uint256 newTokensNumber =
            allowance[oldTokensHolder][msg.sender].sub(tokensNumber);

        approve(oldTokensHolder, msg.sender, newTokensNumber);

        bytes memory emptyData;
        string memory emptyCustomFallback;

        transfer(
            oldTokensHolder,
            newTokensHolder,
            tokensNumber,
            emptyData,
            emptyCustomFallback,
            true
        );

        emit Transfer(
            msg.sender,
            oldTokensHolder,
            newTokensHolder,
            tokensNumber
        );

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function approve(address tokensSpender, uint256 newTokensNumber)
        public checkPayloadSize(2 * 32) returns(bool) {
        //An Attack Vector on Approve/TransferFrom Methods:
        //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(
            allowance[msg.sender][tokensSpender] == 0 || newTokensNumber == 0
        );

        approve(msg.sender, tokensSpender, newTokensNumber);

        return true;
    }

    //For backward compatibility with ERC20.
    //
    //An Attack Vector on Approve/TransferFrom Methods:
    //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    //
    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function approve(
        address tokensSpender,
        uint256 oldTokensNumber,
        uint256 newTokensNumber
    ) public checkPayloadSize(3 * 32) returns(bool) {
        require(allowance[msg.sender][tokensSpender] == oldTokensNumber);

        approve(msg.sender, tokensSpender, newTokensNumber);

        emit Approval(
            msg.sender,
            tokensSpender,
            oldTokensNumber,
            newTokensNumber
        );

        return true;
    }

    //ERC20 Short Address Attack:
    //https://vessenes.com/the-erc20-short-address-attack-explained
    //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
    //https://ericrafaloff.com/analyzing-the-erc20-short-address-attack
    function privilegedTransfer(address newTokensHolder, uint256 tokensNumber)
        public
        checkPayloadSize(2 * 32)
        onlyPrivileged
        onlyPrivilegedTransferNotLocked
        returns(bool) {
        bytes memory emptyData;
        string memory emptyCustomFallback;

        transfer(
            this,
            newTokensHolder,
            tokensNumber,
            emptyData,
            emptyCustomFallback,
            false
        );

        return true;
    }

    function privilegedTransfer(
        address newTokensHolder,
        uint256 tokensNumber,
        bytes data
    ) public onlyPrivileged onlyPrivilegedTransferNotLocked returns(bool) {
        string memory emptyCustomFallback;

        transfer(
            this,
            newTokensHolder,
            tokensNumber,
            data,
            emptyCustomFallback,
            false
        );

        return true;
    }

    function privilegedTransfer(
        address newTokensHolder,
        uint256 tokensNumber,
        bytes data,
        string customFallback
    ) public onlyPrivileged onlyPrivilegedTransferNotLocked returns(bool)  {
        transfer(
            this,
            newTokensHolder,
            tokensNumber,
            data,
            customFallback,
            false
        );

        return true;
    }

    function mint(uint256 tokensNumber)
        public onlyPrivileged onlyPrivilegedMintNotLocked returns(bool) {
        totalSupply = totalSupply.add(tokensNumber);

        balanceOf[this] =
            balanceOf[this].add(tokensNumber * 10 ** uint256(decimals));

        emit Mint(tokensNumber);

        return true;
    }

    function tokenFallback(
        address oldTokensHolder,
        uint256 tokensNumber,
        bytes data
    ) external onlyThisToken onlyEmptyData(data) onlyPrivilegedTransferLocked {
        emit Burn(oldTokensHolder, tokensNumber);
    }

    function transfer(
        address oldTokensHolder,
        address newTokensHolder,
        uint256 tokensNumber,
        bytes data,
        string customFallback,
        //For backward compatibility with ERC20.
        bool isTransferFrom
    ) private {
        balanceOf[oldTokensHolder] =
            balanceOf[oldTokensHolder].sub(tokensNumber);

        balanceOf[newTokensHolder] =
            balanceOf[newTokensHolder].add(tokensNumber);

        if(!isTransferFrom && isContract(newTokensHolder)) {
            if(bytes(customFallback).length > 0) {
                require(callCustomTokenFallback(
                    oldTokensHolder,
                    newTokensHolder,
                    tokensNumber,
                    customFallback,
                    data
                ));
            } else
            //For backward compatibility with ERC20.
            //
            //It is necessary to support a vulnerability in ERC20, without
            //which something can break.
            if(isForceExecute(oldTokensHolder)) {
                emit BadWay();

                if(!callTokenFallback(
                    oldTokensHolder,
                    newTokensHolder,
                    tokensNumber,
                    data
                )) {
                    emit PossibleLossTokens();
                }
            } else {
                ERC223Receiver receiver = ERC223Receiver(newTokensHolder);

                receiver.tokenFallback(oldTokensHolder, tokensNumber, data);
            }
        }

        //For backward compatibility with ERC20.
        emit Transfer(oldTokensHolder, newTokensHolder, tokensNumber);

        emit Transfer(oldTokensHolder, newTokensHolder, tokensNumber, data);
    }

    function isContract(address tokensHolder) private constant returns(bool) {
        uint256 length;

        assembly {
            length := extcodesize(tokensHolder)
        }

        return length > 0;
    }

    //For backward compatibility with ERC20.
    //
    //It is necessary to support a vulnerability in ERC20, without which
    //something can break.
    function isForceExecute(address tokensHolder)
        private constant returns(bool) {
        return forceExecuteOf[tokensHolder] == TernarySwitch.Enabled ||
               forceExecuteOf[tokensHolder] == TernarySwitch.Undefined &&
               (isContract(tokensHolder) && forceExecuteOfContracts ||
                !isContract(tokensHolder) && forceExecuteOfUsers);
    }

    function callCustomTokenFallback(
        address oldTokensHolder,
        address newTokensHolder,
        uint256 tokensNumber,
        string customFallback,
        bytes data
    ) private returns(bool) {
        return newTokensHolder.call(bytes4(keccak256(
            abi.encodePacked(customFallback))
        ), oldTokensHolder, tokensNumber, data);
    }

    function callTokenFallback(
        address oldTokensHolder,
        address newTokensHolder,
        uint256 tokensNumber,
        bytes data
    ) private returns(bool) {
        return callCustomTokenFallback(
            oldTokensHolder,
            newTokensHolder,
            tokensNumber,
            &quot;tokenFallback(address,uint256,bytes)&quot;,
            data
        );
    }

    //For backward compatibility with ERC20.
    function approve(
        address tokensHolder,
        address tokensSpender,
        uint256 newTokensNumber
    ) private {
        allowance[tokensHolder][tokensSpender] = newTokensNumber;

        emit Approval(msg.sender, tokensSpender, newTokensNumber);
    }
}