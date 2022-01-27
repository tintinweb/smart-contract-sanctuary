// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/MintERC721Lib.sol";
import "../utils/SignatureLib.sol";
import "../interfaces/IChocoMintERC721.sol";

contract ChocoMintERC721BulkMinter {
  function mint(
    address chocoMintERC721,
    MintERC721Lib.MintERC721Data[] memory mintERC721Data,
    SignatureLib.SignatureData[] memory signatureData
  ) external {
    require(mintERC721Data.length == signatureData.length, "ChocoMintERC721BulkMinter: length verification failed");
    for (uint256 i = 0; i < mintERC721Data.length; i++) {
      IChocoMintERC721(chocoMintERC721).mint(mintERC721Data[i], signatureData[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SecurityLib.sol";
import "./SignatureLib.sol";

library MintERC721Lib {
  struct MintERC721Data {
    SecurityLib.SecurityData securityData;
    address minter;
    address to;
    uint256 tokenId;
    bytes data;
  }

  bytes32 private constant _MINT_ERC721_TYPEHASH =
    keccak256(
      bytes(
        "MintERC721Data(SecurityData securityData,address minter,address to,uint256 tokenId,bytes data)SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"
      )
    );

  function hashStruct(MintERC721Data memory mintERC721Data) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _MINT_ERC721_TYPEHASH,
          SecurityLib.hashStruct(mintERC721Data.securityData),
          mintERC721Data.minter,
          mintERC721Data.to,
          mintERC721Data.tokenId,
          keccak256(mintERC721Data.data)
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SignatureLib {
  struct SignatureData {
    bytes32 root;
    bytes32[] proof;
    bytes signature;
  }

  bytes32 private constant _SIGNATURE_DATA_TYPEHASH = keccak256(bytes("SignatureData(bytes32 root)"));

  function hashStruct(SignatureData memory signatureData) internal pure returns (bytes32) {
    return keccak256(abi.encode(_SIGNATURE_DATA_TYPEHASH, signatureData.root));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/MintERC721Lib.sol";
import "../utils/SignatureLib.sol";

interface IChocoMintERC721 {
  event Minted(bytes32 indexed mintERC721Hash);

  function mint(MintERC721Lib.MintERC721Data memory mintERC721Data, SignatureLib.SignatureData memory signatureData)
    external;

  function isMinted(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SecurityLib {
  struct SecurityData {
    uint256 validFrom;
    uint256 validTo;
    uint256 salt;
  }

  bytes32 private constant _SECURITY_TYPEHASH =
    keccak256(abi.encodePacked("SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"));

  function validate(SecurityData memory securityData) internal view returns (bool, string memory) {
    if (securityData.validFrom > block.timestamp) {
      return (false, "SecurityLib: valid from verification failed");
    }

    if (securityData.validTo < block.timestamp) {
      return (false, "SecurityLib: valid to verification failed");
    }
    return (true, "");
  }

  function hashStruct(SecurityData memory securityData) internal pure returns (bytes32) {
    return keccak256(abi.encode(_SECURITY_TYPEHASH, securityData.validFrom, securityData.validTo, securityData.salt));
  }
}