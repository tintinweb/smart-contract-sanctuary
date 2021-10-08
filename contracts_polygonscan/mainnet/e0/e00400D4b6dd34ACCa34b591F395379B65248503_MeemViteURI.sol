// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './Base64.sol';

contract MeemViteURI {
	function uint2str(uint256 _i)
		internal
		pure
		returns (string memory _uintAsString)
	{
		if (_i == 0) {
			return '0';
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function tokenURI(uint256 tokenId) public pure returns (string memory) {
		string memory output = string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(
					bytes(
						abi.encodePacked(
							abi.encodePacked(
								'{"name":"MeemVite Seat #',
								uint2str(tokenId),
								'","description":"Join us at https://discord.gg/5NP8PYN8","external_url":"https://meem.wtf/","image":"data:image/svg+xml;base64,'
							),
							Base64.encode(
								abi.encodePacked(
									'<svg width="1793" height="958" fill="none" xmlns="http://www.w3.org/2000/svg"><style>.info {fill: black;font-family: Courier, monospace; font-size: 60px; font-weight: 400;}</style><mask id="prefix__a" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="1793" height="958"><path fill="url(#prefix__paint0_radial)" d="M0 0h1793v958H0z"/></mask><g mask="url(#prefix__a)"><path opacity=".3" fill="#F8FAF4" d="M0 0h1793v958H0z"/><mask id="prefix__b" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="96" y="96" width="1601" height="766"><path fill="#C4C4C4" d="M96 96h1601v766H96z"/></mask><g mask="url(#prefix__b)"><path fill="#F8FAF4" d="M0 0h1793v958H0z"/></g><g style="mix-blend-mode:multiply" filter="url(#prefix__filter0_f)"><circle cx="649" cy="-335" r="669" fill="#B4F2DF"/></g><g style="mix-blend-mode:multiply" filter="url(#prefix__filter1_f)"><circle cx="1307" cy="1238" r="669" fill="#B4F2DF"/></g><path opacity=".8" d="M359.6 735h17.216v-1.696h-15.328v-20.8H359.6V735zm21.849 0h21.952v-1.696h-20.096v-9.12h18.496v-1.696h-18.496v-8.256h19.776v-1.728h-21.632V735zm37.499 0h2.144l12.032-22.496h-2.112l-10.944 20.512h-.032l-11.008-20.512h-2.112L418.948 735zm18.667 0h21.952v-1.696h-20.096v-9.12h18.496v-1.696h-18.496v-8.256h19.776v-1.728h-21.632V735zm27.068 0h17.216v-1.696h-15.328v-20.8h-1.888V735z" fill="#211D28"/><path d="M380.11 819.375c6.93 0 12.65-3.355 16.005-8.855h.055l.44 7.48h3.85v-21.395h-26.235v4.07h21.56c0 8.36-6.765 14.63-15.29 14.63-9.295 0-16.005-7.04-16.005-16.665 0-9.79 6.38-16.72 15.29-16.72 5.775 0 10.835 3.74 12.65 9.02l4.235-1.375c-2.31-6.82-9.13-11.715-16.83-11.715-11.55 0-19.91 8.745-19.91 20.79 0 11.99 8.47 20.735 20.185 20.735zm40.619-30.305c-3.52 0-6.49 2.145-8.03 5.5h-.055l-.385-4.345h-3.575V818h4.18v-15.29c0-6.05 2.805-9.735 7.26-9.735 3.025 0 5.06 2.09 5.5 5.995l3.63-1.21c-.55-5.555-3.795-8.69-8.525-8.69zm28.851 30.03c8.965 0 14.85-5.94 14.85-14.96 0-9.075-5.885-15.015-14.85-15.015-8.91 0-14.795 5.94-14.795 15.015 0 9.02 5.885 14.96 14.795 14.96zm0-3.795c-6.435 0-10.615-4.4-10.615-11.165 0-6.765 4.18-11.165 10.615-11.165 6.435 0 10.615 4.4 10.615 11.165 0 6.765-4.18 11.165-10.615 11.165zm32.54 3.795c4.84 0 8.305-1.87 10.67-5.225h.055l.385 4.125h3.795v-27.775h-4.18V805.9c0 5.665-4.015 9.57-9.57 9.57-4.4 0-7.205-3.025-7.205-7.755v-17.49h-4.235v17.93c0 6.875 3.905 10.945 10.285 10.945zm38.595-29.975c-4.84 0-8.305 1.87-10.67 5.225h-.055l-.385-4.125h-3.795V818h4.18v-15.675c0-5.665 4.015-9.57 9.57-9.57 4.4 0 7.205 3.025 7.205 7.755V818H531v-17.93c0-6.875-3.905-10.945-10.285-10.945zm31.831 29.975c4.62 0 8.47-2.2 10.835-5.885h.055l.385 4.785h3.685v-40.425h-4.235V794.9h-.055c-2.365-3.63-6.105-5.775-10.725-5.775-8.14 0-14.08 6.325-14.08 15.015 0 8.635 5.995 14.96 14.135 14.96zm.495-3.795c-5.995 0-10.45-4.785-10.45-11.165 0-6.325 4.4-11.165 10.45-11.165 5.995 0 10.395 4.84 10.395 11.165 0 6.27-4.4 11.165-10.395 11.165zM595.162 818h4.565v-17.38h16.665v-3.905h-16.665v-13.42h19.91v-4.07h-24.475V818zm31.646 0h4.18v-40.425h-4.18V818zm26.663 1.1c8.965 0 14.85-5.94 14.85-14.96 0-9.075-5.885-15.015-14.85-15.015-8.91 0-14.795 5.94-14.795 15.015 0 9.02 5.885 14.96 14.795 14.96zm0-3.795c-6.435 0-10.615-4.4-10.615-11.165 0-6.765 4.18-11.165 10.615-11.165 6.435 0 10.615 4.4 10.615 11.165 0 6.765-4.18 11.165-10.615 11.165zm36.225 3.795c8.965 0 14.85-5.94 14.85-14.96 0-9.075-5.885-15.015-14.85-15.015-8.91 0-14.795 5.94-14.795 15.015 0 9.02 5.885 14.96 14.795 14.96zm0-3.795c-6.435 0-10.615-4.4-10.615-11.165 0-6.765 4.18-11.165 10.615-11.165 6.435 0 10.615 4.4 10.615 11.165 0 6.765-4.18 11.165-10.615 11.165zm34.575-26.235c-3.52 0-6.49 2.145-8.03 5.5h-.055l-.385-4.345h-3.575V818h4.18v-15.29c0-6.05 2.805-9.735 7.26-9.735 3.025 0 5.06 2.09 5.5 5.995l3.63-1.21c-.55-5.555-3.795-8.69-8.525-8.69z" fill="#211D28"/><path opacity=".8" d="M161.208 735.8c6.496 0 10.784-2.688 10.784-6.848 0-3.264-2.56-5.088-8.48-6.016l-6.336-1.024c-4.032-.608-5.728-1.76-5.728-3.776 0-2.816 3.072-4.704 7.648-4.704 4.256 0 7.84 1.856 9.28 4.576l1.504-1.056c-1.632-3.136-5.824-5.248-10.784-5.248-5.664 0-9.536 2.528-9.536 6.528 0 3.072 2.176 4.64 7.264 5.44l6.432 1.056c4.8.768 6.848 2.144 6.848 4.416 0 2.912-3.488 4.928-8.832 4.928-6.112 0-10.976-2.752-12.032-6.88l-1.6.96c1.44 4.576 6.752 7.648 13.568 7.648zm15.897-.8h21.952v-1.696h-20.096v-9.12h18.496v-1.696h-18.496v-8.256h19.776v-1.728h-21.632V735zm25.628 0h2.016l3.072-5.664h16.16l3.104 5.664h1.984l-12.032-22.496h-2.208L202.733 735zm5.984-7.36l7.168-13.504h.064l7.168 13.504h-14.4zm30.777 7.36h1.888v-20.768h10.976v-1.728H228.55v1.728h10.944V735z" fill="#211D28"/><path fill-rule="evenodd" clip-rule="evenodd" d="M152 620.186h29.138V303.62h.988l183.717 316.566h33.583L583.637 303.62h.988v316.566h624.245V303.62h.49l183.72 316.566h33.58l184.21-316.566h.99v316.566H1641V273h-44.94l-185.69 319.036h-.5L1224.18 273H568.821L383.128 592.036h-.494L196.942 273H152v347.186zm1027.24-320.517H615.244v127.417H1179.24V299.669zm0 153.591H615.244v140.751h563.996V453.26z" fill="#3F374D"/><path stroke="#211D28" d="M95.5 95.5h1602v767H95.5zM96 186.5h1601"/><path d="M171.72 159.2c13.632 0 22.8-7.296 22.8-18.048 0-10.752-9.168-18.096-22.8-18.096-13.584 0-22.8 7.344-22.8 18.096 0 10.752 9.216 18.048 22.8 18.048zm0-2.544c-11.904 0-19.968-6.288-19.968-15.504s8.064-15.504 19.968-15.504 19.968 6.288 19.968 15.504-8.064 15.504-19.968 15.504zM201.733 158h2.832v-30.864h.048L233.221 158h3.84v-33.744h-2.832v30.912h-.048l-28.608-30.912h-3.84V158zM244.738 158h32.928v-2.544h-30.144v-13.68h27.744v-2.544h-27.744v-12.384h29.664v-2.592h-32.448V158zM1336.87 158h2.83v-30.768h.09L1357.65 158h3.26l17.91-30.768h.09V158h2.84v-33.744h-4.37l-18.05 31.008h-.05l-18.05-31.008h-4.36V158zM1389.43 158h32.93v-2.544h-30.14v-13.68h27.74v-2.544h-27.74v-12.384h29.66v-2.592h-32.45V158zM1428.59 158h32.93v-2.544h-30.14v-13.68h27.74v-2.544h-27.74v-12.384h29.66v-2.592h-32.45V158zM1467.76 158h2.83v-30.768h.09L1488.54 158h3.26l17.91-30.768h.09V158h2.84v-33.744h-4.37l-18.05 31.008h-.05l-18.05-31.008h-4.36V158zM1535.97 158h3.22l18.04-33.744h-3.16l-16.42 30.768h-.05l-16.51-30.768h-3.17L1535.97 158zM1562.53 158h2.83v-33.744h-2.83V158zM1587.31 158h2.83v-31.152h16.46v-2.592h-35.71v2.592h16.42V158zM1612.12 158h32.93v-2.544h-30.15v-13.68h27.75v-2.544h-27.75v-12.384h29.67v-2.592h-32.45V158z" fill="#211D28"/><path d="M306.5 153a12.501 12.501 0 000-25v25zM1306.5 153c-3.32 0-6.49-1.317-8.84-3.661a12.517 12.517 0 01-3.66-8.839c0-3.315 1.32-6.495 3.66-8.839a12.505 12.505 0 018.84-3.661v25z" fill="#4A4159"/></g><defs><filter id="prefix__filter0_f" x="-320" y="-1304" width="1938" height="1938" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="150" result="effect1_foregroundBlur"/></filter><filter id="prefix__filter1_f" x="338" y="269" width="1938" height="1938" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="150" result="effect1_foregroundBlur"/></filter><radialGradient id="prefix__paint0_radial" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(883.5 0 0 1653.57 883.5 479)"><stop offset=".74" stop-color="#4A4159"/><stop offset=".964" stop-color="#211D28"/></radialGradient></defs><text x="142" y="820" class="info">',
									padToFour(tokenId),
									'</text></svg>'
								)
							),
							abi.encodePacked(
								'","background_color":"000000","attributes":[{"trait_type":"Level","value":"Ground Floor"}, {"trait_type":"Seat","value":"',
								padToFour(tokenId),
								'"}]}'
							)
						)
					)
				)
			)
		);

		return output;
	}

	function padToFour(uint256 num) public pure returns (string memory) {
		if (num < 1000 && num > 99) {
			return string(abi.encodePacked('0', uint2str(num)));
		} else if (num < 100 && num > 9) {
			return string(abi.encodePacked('00', uint2str(num)));
		} else if (num < 10) {
			return string(abi.encodePacked('000', uint2str(num)));
		}

		return uint2str(num);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
	bytes internal constant TABLE =
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return '';

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((len + 2) / 3);

		// Add some extra buffer at the end
		bytes memory result = new bytes(encodedLen + 32);

		bytes memory table = TABLE;

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)

			for {
				let i := 0
			} lt(i, len) {

			} {
				i := add(i, 3)
				let input := and(mload(add(data, i)), 0xffffff)

				let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
				)
				out := shl(224, out)

				mstore(resultPtr, out)

				resultPtr := add(resultPtr, 4)
			}

			switch mod(len, 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}

			mstore(result, encodedLen)
		}

		return string(result);
	}
}