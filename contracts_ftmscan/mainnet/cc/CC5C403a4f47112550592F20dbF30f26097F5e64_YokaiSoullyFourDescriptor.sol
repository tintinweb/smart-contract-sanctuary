// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "../interfaces/IYokaiHeroesDescriptor.sol";

/// @title Describes Yokai
/// @notice Produces a string containing the data URI for a JSON metadata string
contract YokaiSoullyFourDescriptor is IYokaiHeroesDescriptor {

    /// @inheritdoc IYokaiHeroesDescriptor
    function tokenURI() external view override returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage()));
        string memory name = 'Soully Yokai #4';
        string memory description = generateDescription();

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage() private pure returns (string memory){
        return '<svg id="Soully Yokai" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="420" height="420" viewBox="0 0 420 420"> <g id="background"><g id="Unreal"><radialGradient id="radial-gradient" cx="210.05" cy="209.5" r="209.98" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#634363"/><stop offset="1" stop-color="#04061c"/></radialGradient><path d="M389.9,419.5H30.1a30,30,0,0,1-30-30V29.5a30,30,0,0,1,30-30H390a30,30,0,0,1,30,30v360A30.11,30.11,0,0,1,389.9,419.5Z" transform="translate(0 0.5)" fill="url(#radial-gradient)"/> <g> <path id="Main_Spin" fill="#000" stroke="#000" stroke-miterlimit="10" d="M210,63.3c-192.6,3.5-192.6,290,0,293.4 C402.6,353.2,402.6,66.7,210,63.3z M340.8,237.5c-0.6,2.9-1.4,5.7-2.2,8.6c-43.6-13.6-80.9,37.8-54.4,75.1 c-4.9,3.2-10.1,6.1-15.4,8.8c-33.9-50.6,14.8-117.8,73.3-101.2C341.7,231.7,341.4,234.6,340.8,237.5z M331.4,265.5 c-7.9,17.2-19.3,32.4-33.3,44.7c-15.9-23.3,7.6-55.7,34.6-47.4C332.3,263.7,331.8,264.6,331.4,265.5z M332.5,209.6 C265,202.4,217,279,252.9,336.5c-5.8,1.9-11.7,3.5-17.7,4.7c-40.3-73.8,24.6-163.5,107.2-148c0.6,6,1.2,12.2,1.1,18.2 C339.9,210.6,336.2,210,332.5,209.6z M87.8,263.9c28.7-11.9,56,24,36.3,48.4C108.5,299.2,96.2,282.5,87.8,263.9z M144.3,312.7 c17.8-38.8-23.4-81.6-62.6-65.5c-1.7-5.7-2.9-11.5-3.7-17.4c60-20.6,112.7,49.4,76,101.5c-5.5-2.4-10.7-5.3-15.6-8.5 C140.7,319.6,142.7,316.3,144.3,312.7z M174.2,330.4c32.6-64-28.9-138.2-97.7-118c-0.3-6.1,0.4-12.4,0.9-18.5 c85-18.6,151.7,71.7,110.8,147.8c-6.1-1-12.2-2.4-18.1-4.1C171.6,335.3,173,332.9,174.2,330.4z M337,168.6c-7-0.7-14.4-0.8-21.4-0.2 c-43.1-75.9-167.4-75.9-210.7-0.2c-7.3-0.6-14.9,0-22.1,0.9C118.2,47.7,301.1,47.3,337,168.6z M281.1,175.9c-3,1.1-5.9,2.3-8.7,3.6 c-29.6-36.1-93.1-36.7-123.4-1.2c-5.8-2.5-11.9-4.5-18-6.1c36.6-50.4,122.9-50,159,0.7C286.9,173.8,284,174.8,281.1,175.9z M249.6,193.1c-2.4,1.8-4.7,3.6-7,5.6c-16.4-15.6-46-16.4-63.2-1.5c-4.7-3.8-9.6-7.3-14.7-10.5c23.9-24.1,69.1-23.5,92.2,1.3 C254.4,189.6,252,191.3,249.6,193.1z M211.9,239.2c-5.2-10.8-11.8-20.7-19.7-29.4c10.7-8.1,27.9-7.3,37.9,1.6 C222.8,219.7,216.7,229.1,211.9,239.2z"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </path> <g id="Spin_Inverse"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2609,22.2609" cx="210" cy="210" r="163"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> <g id="Spin"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2041,22.2041" cx="210" cy="210" r="183.8"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> </g></g></g> <g id="Body"> <g id="Yokai"> <path id="Neck" d="M176,277.2c.8,10,1.1,20.2-.7,30.4a9.46,9.46,0,0,1-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2-8.1,2.3-9.5,12.4-2.1,16.4,71.9,38.5,146.3,42.5,224.4,7,7.2-3.3,7.3-12.7.1-16-22.3-10.3-43.5-23.1-54.9-29.9a10.93,10.93,0,0,1-5.1-8.3,126.62,126.62,0,0,1-.1-22.2,161,161,0,0,1,4.6-29.3" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ombre" d="M178.3,279.4s24.2,35,41,30.6S261,288.4,261,288.4c1.2-9.1,1.9-17.1,3.7-26-4.8,4.9-10.4,9.2-18.8,14.5a109.19,109.19,0,0,1-29.8,13.3Z" fill="#7099ae" fill-rule="evenodd"/> <path id="Head" d="M314.1,169.2c-.6-.8-12.2,8.3-12.2,8.3.3-4.9,11.8-53.1-17.3-86-15.9-17.4-42.2-27.1-69.9-27.7-24.5-.5-48.7,10.9-61.6,24.4-33.5,35-20.1,98.2-20.1,98.2.6,10.9,9.1,63.4,21.3,74.6,0,0,33.7,25.7,42.4,30.6a22.71,22.71,0,0,0,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l.2-.2c6.9-9.1,3.9-5.8,11.2-14.8a4.71,4.71,0,0,1,4.8-1.8c4.1.8,11.7,1.3,13.3-7,2.4-11.5,2.6-25.1,8.6-35.5C311.9,191.2,316.1,185,314.1,169.2Z" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ear" d="M142.1,236.4c.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48C116,164.1,132,183,132,183" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <g id="Ear2"> <path d="M304.4,175.6a10.14,10.14,0,0,1-2.3,3.5c-.9.8-1.7,1.4-2.6,2.2-1.8,1.7-3.9,3.2-5.5,5.2a53.07,53.07,0,0,0-4.2,6.3c-.6,1-1.3,2.2-1.9,3.3l-1.7,3.4-.2-.1,1.4-3.6c.5-1.1.9-2.4,1.5-3.5a56.34,56.34,0,0,1,3.8-6.8,23.83,23.83,0,0,1,5.1-5.9,22,22,0,0,1,3.2-2.1,12.65,12.65,0,0,0,3.1-2Z"/> </g> <g id="Buste"> <path d="M222.4,340.1c4.6-.4,9.3-.6,13.9-.9l14-.6c4.7-.1,9.3-.3,14-.4l7-.1h7c-2.3.2-4.6.3-7,.5l-7,.4-14,.6c-4.7.1-9.3.3-14,.4C231.8,340.1,227.1,340.2,222.4,340.1Z" fill="#2b232b"/> <path d="M142.5,337.6c4.3,0,8.4.1,12.6.2s8.4.3,12.6.5,8.4.4,12.6.7l6.4.4c2.1.2,4.2.3,6.4.5-2.1,0-4.2,0-6.4-.1l-6.4-.2c-4.2-.1-8.4-.3-12.6-.5s-8.4-.4-12.6-.7C151,338.4,146.9,338,142.5,337.6Z" fill="#2b232b"/> <path d="M199.5,329.6l1.6,3c.5,1,1,2,1.6,3a16.09,16.09,0,0,0,1.7,2.8c.2.2.3.4.5.6s.3.2.3.2a3.1,3.1,0,0,0,1.3-.6c1.8-1.3,3.4-2.8,5.1-4.3.8-.7,1.7-1.6,2.5-2.3l2.5-2.3a53.67,53.67,0,0,1-4.4,5.1,27.94,27.94,0,0,1-5.1,4.6,1.61,1.61,0,0,1-.7.4,1.69,1.69,0,0,1-1,.3,1.85,1.85,0,0,1-.7-.2c-.1-.1-.3-.2-.4-.3s-.4-.5-.6-.7c-.6-.9-1.1-2-1.7-3A55,55,0,0,1,199.5,329.6Z" fill="#2b232b"/> <path d="M199.5,329.6s3.5,9.3,5.3,10.1,11.6-10,11.6-10C210.1,331.3,204.2,331.5,199.5,329.6Z" fill-rule="evenodd" opacity="0.19" style="isolation: isolate"/> </g> </g> <g> <line x1="128.5" y1="179.3" x2="134.3" y2="186.7" fill="none"/> <path d="M128.5,179.3a11,11,0,0,1,5.7,7.4A11.58,11.58,0,0,1,128.5,179.3Z"/> </g> </g> <g id="Eyes"> <g id="Shine"> <g> <g id="No_Fill"> <g> <path d="M219.3,197.7s3.1-22.5,37.9-15.5C257.3,182.1,261.2,209.2,219.3,197.7Z" stroke="#000" stroke-miterlimit="10"/> <path d="M227.5,182.5a13.5,13.5,0,0,0-2.7,2c-.8.7-1.6,1.6-2.3,2.3a25.25,25.25,0,0,0-2.1,2.5l-1,1.4c-.3.4-.6.9-1,1.4.2-.5.4-1,.6-1.6a11.94,11.94,0,0,1,.8-1.6,17.57,17.57,0,0,1,4.7-5.1A4.82,4.82,0,0,1,227.5,182.5Z"/> <path d="M245.6,201.3a14.79,14.79,0,0,0,3.6-1,20.16,20.16,0,0,0,3.2-1.8,16,16,0,0,0,2.7-2.5c.8-1,1.6-2,2.3-3a7.65,7.65,0,0,1-1.7,3.5,12.4,12.4,0,0,1-2.8,2.8,11.37,11.37,0,0,1-3.5,1.7A7,7,0,0,1,245.6,201.3Z"/> </g> <g> <path d="M184.1,197.7s-3.1-22.5-37.9-15.5C146.2,182.1,142.2,209.2,184.1,197.7Z" stroke="#000" stroke-miterlimit="10"/> <path d="M176,182.5a13.5,13.5,0,0,1,2.7,2c.8.7,1.6,1.6,2.3,2.3a25.25,25.25,0,0,1,2.1,2.5l1,1.4c.3.4.6.9,1,1.4-.2-.5-.4-1-.6-1.6a11.94,11.94,0,0,0-.8-1.6,17.57,17.57,0,0,0-4.7-5.1A5.45,5.45,0,0,0,176,182.5Z"/> <path d="M157.8,201.3a14.79,14.79,0,0,1-3.6-1,20.16,20.16,0,0,1-3.2-1.8,16,16,0,0,1-2.7-2.5c-.8-1-1.6-2-2.3-3a7.65,7.65,0,0,0,1.7,3.5,12.4,12.4,0,0,0,2.8,2.8A11.37,11.37,0,0,0,154,201,8.1,8.1,0,0,0,157.8,201.3Z"/> </g> </g> <g id="Shadow" opacity="0.43"> <path d="M218.5,192s4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8C219.1,184.2,218.5,192,218.5,192Z" opacity="0.5" style="isolation: isolate"/> </g> <g id="Shadow" opacity="0.43"> <path d="M185.1,191.7s-4.8-10.6-20.1-13.4c0,0,12.4-.2,16.3,2.6C184.6,184,185.1,191.7,185.1,191.7Z" opacity="0.5" style="isolation: isolate"/> </g> </g> <path d="M164.3,182.9c1.4,7,1.4,6.9,8.3,8.3-7,1.4-6.9,1.4-8.3,8.3-1.4-7-1.4-6.9-8.3-8.3C163,189.8,162.9,189.9,164.3,182.9Z" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.5"/> <path d="M238.9,182.7c1.4,7,1.4,6.9,8.3,8.3-7,1.4-6.9,1.4-8.3,8.3-1.4-7-1.4-6.9-8.3-8.3C237.6,189.6,237.5,189.6,238.9,182.7Z" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.5"/> </g> <g id="Shine"> <g> <g id="No_Fill" > <g> <path d="M219.3,197.7s3.1-22.5,37.9-15.5C257.3,182.1,261.2,209.2,219.3,197.7Z" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M227.5,182.5a13.5,13.5,0,0,0-2.7,2c-.8.7-1.6,1.6-2.3,2.3a25.25,25.25,0,0,0-2.1,2.5l-1,1.4c-.3.4-.6.9-1,1.4.2-.5.4-1,.6-1.6a11.94,11.94,0,0,1,.8-1.6,17.57,17.57,0,0,1,4.7-5.1A4.82,4.82,0,0,1,227.5,182.5Z"/> <path d="M245.6,201.3a14.79,14.79,0,0,0,3.6-1,20.16,20.16,0,0,0,3.2-1.8,16,16,0,0,0,2.7-2.5c.8-1,1.6-2,2.3-3a7.65,7.65,0,0,1-1.7,3.5,12.4,12.4,0,0,1-2.8,2.8,11.37,11.37,0,0,1-3.5,1.7A7,7,0,0,1,245.6,201.3Z"/> </g> <g> <path d="M184.1,197.7s-3.1-22.5-37.9-15.5C146.2,182.1,142.2,209.2,184.1,197.7Z" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M176,182.5a13.5,13.5,0,0,1,2.7,2c.8.7,1.6,1.6,2.3,2.3a25.25,25.25,0,0,1,2.1,2.5l1,1.4c.3.4.6.9,1,1.4-.2-.5-.4-1-.6-1.6a11.94,11.94,0,0,0-.8-1.6,17.57,17.57,0,0,0-4.7-5.1A5.45,5.45,0,0,0,176,182.5Z"/> <path d="M157.8,201.3a14.79,14.79,0,0,1-3.6-1,20.16,20.16,0,0,1-3.2-1.8,16,16,0,0,1-2.7-2.5c-.8-1-1.6-2-2.3-3a7.65,7.65,0,0,0,1.7,3.5,12.4,12.4,0,0,0,2.8,2.8A11.37,11.37,0,0,0,154,201,8.1,8.1,0,0,0,157.8,201.3Z"/> </g> </g> <g id="Shadow" opacity="0.43"> <path d="M218.5,192s4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8C219.1,184.2,218.5,192,218.5,192Z" opacity="0.5" style="isolation: isolate"/> </g> <g id="Shadow" opacity="0.43"> <path d="M185.1,191.7s-4.8-10.6-20.1-13.4c0,0,12.4-.2,16.3,2.6C184.6,184,185.1,191.7,185.1,191.7Z" opacity="0.5" style="isolation: isolate"/> </g> </g> <path d="M164.3,182.9c1.4,7,1.4,6.9,8.3,8.3-7,1.4-6.9,1.4-8.3,8.3-1.4-7-1.4-6.9-8.3-8.3C163,189.8,162.9,189.9,164.3,182.9Z" fill="#52d784" stroke="#2f3555" stroke-miterlimit="10" stroke-width="0.5"/> <path d="M238.9,182.7c1.4,7,1.4,6.9,8.3,8.3-7,1.4-6.9,1.4-8.3,8.3-1.4-7-1.4-6.9-8.3-8.3C237.6,189.6,237.5,189.6,238.9,182.7Z" fill="#60d5dc" stroke="#2f3555" stroke-miterlimit="10" stroke-width="0.5"/> </g> </g> <g id="Hair"> <g id="Flame"> <path d="M292.4,169.2,282,177.3c3.5-8,7-18.9,7.2-24-2.4,1.6-6.8,4.7-9.3,4.1,3.9-12.3,4.2-11.6,4.6-24.2-2.5,2-8.9,9.3-11.5,11.2.5-5.9.8-14.3,1.4-20.1-3.3,3.4-7.6,2.6-12.5,4-.5-5,1.3-7,3.5-11.6-9.8,4-24.7,6-34.9,8.6-.1-2.4-.6-6.3.7-8.1-10.4,5-26.7,9.3-31.8,12.4-4.1-2.8-16.9-9.3-19.7-12.9-.1,1.6.7,8,.6,9.6-5.4-3.8-6.2-3-12-6.8.5,2.6.3,3.6.8,6.2-7.2-2.8-14.4-5.7-21.6-8.5,1.8,4,3.5,8,5.3,12-3.6.6-9.9-1.8-12-4.9-3,7.8-.1,12.2,0,20.5-2-2-3.9-6.4-5.4-8.6.5,9.6,1,19.1,1.6,28.7a5.18,5.18,0,0,1-3.1-3.5c-.1,5.8,2.6,20.6,4,26.4-.8-.8-5.5-10.9-5.7-12.1,4.3,7.9,4.1,10.5,5.4,26.3.9-.9.2-6.6-5.1-16.9-1.7-15.4-8.2-36.2-12-51.3,2,3.6,3.9,7.3,5.8,11-.7-13.8-.7-27.6-.1-41.4a49,49,0,0,0,2.6,17.4A150,150,0,0,1,134,87.5a37.4,37.4,0,0,0,1.6,12,248,248,0,0,1,10.3-29.3c.8,4.7,1.7,9.4,2.4,14.1,3.6-9.9,7.9-15.5,14.6-23.7.2,4,.4,7.8.7,11.8a112.84,112.84,0,0,1,24.1-23.2c-.5,4.4-1,8.8-1.6,13.1,6.1-5.7,11.7-9.7,17.8-15.4.3,4.4,1.3,7,1.6,11.5,4-5.4,8.1-9.6,12.1-15A87.39,87.39,0,0,1,219.8,61c4.8-4.7,8.1-10,8.4-16.7,4.2,7.4,7.9,10.6,9.8,18.9,2.5-8.4,4.8-11,4.7-19.8,4.4,10.1,6.8,14.3,9.6,24,.9-4.6,4.1-11.5,5-16,6.3,6.7,9.1,14.6,12.4,23,.7-7.6,5.7-10.6,3.5-17.9,6.5,10.7,4.6,15.2,8.6,27.7,2.9-5.3,4.4-13.3,5.5-19.4,2.7,8,7.7,23.1,9.4,31.5.7-2.7,3.1-3.3,3.5-9.9,2.8,7.7,3.3,8.4,3.5,23.4,1.1-7.4,4.3-3.3,4.5-10.8,3.8,9.6,1.4,14.8.4,22.6-.1.9,4.2-.4,5.1-1.5,1-1.3-2.1,12.4-2.8,14.3-.5,1.4-1.9,2.7-1.4,8.4,2.2-3.1,2.5-3,4.3-6.4,1.3,11.3-2.3,6-4.7,25.5,1.9-2.5,3.9-1.1,5.6-3.5-2.8,7.8-.4,9.8-6.9,14-3.3,2.1-11.2,10.3-14.2,13.5,1.6-3.3-2.9,9.8-8.2,18.8C284.7,199.9,289.9,171.1,292.4,169.2Z" fill="#bfd2d3"/> </g> </g> <g id="Mouth" > <g id="Monster"> <path d="M165.7,242.3l1.4.3c4.3,1.2,36.4,12.1,81.4-1,.1.1-17.5,28.2-43.1,28.6C192.6,270.5,181.3,263.8,165.7,242.3Z" fill="#fff" stroke="#2f3555" stroke-miterlimit="10" stroke-width="0.75"/> <polyline points="168.8 246.2 171.5 244 174.1 253 177.7 245.5 181.9 260.8 188.4 247.2 193 267.7 198.7 248.2 204.2 270.3 209.2 248.3 215.7 268.7 219.5 247.5 225.6 264.4 228.4 246.4 234.2 258.2 236.9 244.9 240.6 251.8 243.3 243.1 246.1 245.5" fill="none" stroke="#2f3555" stroke-linejoin="round" stroke-width="0.75"/> <g opacity="0.52"> <path d="M246.3,239.9a31.21,31.21,0,0,1,5.9-1.9l.6-.1-.2.6c-.6,2.2-1.3,4.4-2.1,6.5a56.25,56.25,0,0,1,1.4-6.9l.4.5A17.43,17.43,0,0,1,246.3,239.9Z"/> </g> <g opacity="0.52"> <path d="M168.2,240.8c-2-.2-4-.5-5.9-.8l.4-.5a46.11,46.11,0,0,1,1.5,7.2,56.82,56.82,0,0,1-2.2-7l-.2-.6.6.1A29.35,29.35,0,0,1,168.2,240.8Z"/> </g> </g> </g> </svg>';
    }

    function generateDescription() private pure returns (string memory){
        return 'yokai\'chain x spiritswap';
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title Describes Yokai via URI
interface IYokaiHeroesDescriptor {
    /// @notice Produces the URI describing a particular Yokai (token id)
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI() external view returns (string memory);
}