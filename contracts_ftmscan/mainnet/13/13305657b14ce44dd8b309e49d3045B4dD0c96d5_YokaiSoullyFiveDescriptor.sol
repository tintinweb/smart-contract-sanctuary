// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "../interfaces/IYokaiHeroesDescriptor.sol";

/// @title Describes Yokai
/// @notice Produces a string containing the data URI for a JSON metadata string
contract YokaiSoullyFiveDescriptor is IYokaiHeroesDescriptor {

    /// @inheritdoc IYokaiHeroesDescriptor
    function tokenURI() external view override returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage()));
        string memory name = 'Soully Yokai #5';
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
        return '<svg id="Soully Yokai" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="420" height="420" viewBox="0 0 420 420"> <g id="background"><g id="Unreal"><radialGradient id="radial-gradient" cx="210.05" cy="209.5" r="209.98" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#634363"/><stop offset="1" stop-color="#04061c"/></radialGradient><path d="M389.9,419.5H30.1a30,30,0,0,1-30-30V29.5a30,30,0,0,1,30-30H390a30,30,0,0,1,30,30v360A30.11,30.11,0,0,1,389.9,419.5Z" transform="translate(0 0.5)" fill="url(#radial-gradient)"/> <g> <path id="Main_Spin" fill="#000" stroke="#000" stroke-miterlimit="10" d="M210,63.3c-192.6,3.5-192.6,290,0,293.4 C402.6,353.2,402.6,66.7,210,63.3z M340.8,237.5c-0.6,2.9-1.4,5.7-2.2,8.6c-43.6-13.6-80.9,37.8-54.4,75.1 c-4.9,3.2-10.1,6.1-15.4,8.8c-33.9-50.6,14.8-117.8,73.3-101.2C341.7,231.7,341.4,234.6,340.8,237.5z M331.4,265.5 c-7.9,17.2-19.3,32.4-33.3,44.7c-15.9-23.3,7.6-55.7,34.6-47.4C332.3,263.7,331.8,264.6,331.4,265.5z M332.5,209.6 C265,202.4,217,279,252.9,336.5c-5.8,1.9-11.7,3.5-17.7,4.7c-40.3-73.8,24.6-163.5,107.2-148c0.6,6,1.2,12.2,1.1,18.2 C339.9,210.6,336.2,210,332.5,209.6z M87.8,263.9c28.7-11.9,56,24,36.3,48.4C108.5,299.2,96.2,282.5,87.8,263.9z M144.3,312.7 c17.8-38.8-23.4-81.6-62.6-65.5c-1.7-5.7-2.9-11.5-3.7-17.4c60-20.6,112.7,49.4,76,101.5c-5.5-2.4-10.7-5.3-15.6-8.5 C140.7,319.6,142.7,316.3,144.3,312.7z M174.2,330.4c32.6-64-28.9-138.2-97.7-118c-0.3-6.1,0.4-12.4,0.9-18.5 c85-18.6,151.7,71.7,110.8,147.8c-6.1-1-12.2-2.4-18.1-4.1C171.6,335.3,173,332.9,174.2,330.4z M337,168.6c-7-0.7-14.4-0.8-21.4-0.2 c-43.1-75.9-167.4-75.9-210.7-0.2c-7.3-0.6-14.9,0-22.1,0.9C118.2,47.7,301.1,47.3,337,168.6z M281.1,175.9c-3,1.1-5.9,2.3-8.7,3.6 c-29.6-36.1-93.1-36.7-123.4-1.2c-5.8-2.5-11.9-4.5-18-6.1c36.6-50.4,122.9-50,159,0.7C286.9,173.8,284,174.8,281.1,175.9z M249.6,193.1c-2.4,1.8-4.7,3.6-7,5.6c-16.4-15.6-46-16.4-63.2-1.5c-4.7-3.8-9.6-7.3-14.7-10.5c23.9-24.1,69.1-23.5,92.2,1.3 C254.4,189.6,252,191.3,249.6,193.1z M211.9,239.2c-5.2-10.8-11.8-20.7-19.7-29.4c10.7-8.1,27.9-7.3,37.9,1.6 C222.8,219.7,216.7,229.1,211.9,239.2z"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </path> <g id="Spin_Inverse"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2609,22.2609" cx="210" cy="210" r="163"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> <g id="Spin"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2041,22.2041" cx="210" cy="210" r="183.8"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> </g></g></g> <defs> <linearGradient id="linear-gradient" x1="141" y1="-181.18" x2="282.8" y2="-181.18" gradientTransform="matrix(1, 0, 0, -1, 0.2, 76.4)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#52d784"/> <stop offset="1" stop-color="#60d5dc"/> </linearGradient> </defs> <g id="Body"> <g id="Yokai"> <path id="Neck" d="M176,277.2c.8,10,1.1,20.2-.7,30.4a9.46,9.46,0,0,1-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2-8.1,2.3-9.5,12.4-2.1,16.4,71.9,38.5,146.3,42.5,224.4,7,7.2-3.3,7.3-12.7.1-16-22.3-10.3-43.5-23.1-54.9-29.9a10.91,10.91,0,0,1-5.1-8.3,126.61,126.61,0,0,1-.1-22.2,161.17,161.17,0,0,1,4.6-29.3" transform="translate(-0.1)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ombre" d="M178.3,279.4s24.2,35,41,30.6S261,288.4,261,288.4c1.2-9.1,1.9-17.1,3.7-26-4.8,4.9-10.4,9.2-18.8,14.5a109.39,109.39,0,0,1-29.8,13.3Z" transform="translate(-0.1)" fill="#7099ae" fill-rule="evenodd"/> <path id="Head" d="M314.1,169.2c-.6-.8-12.2,8.3-12.2,8.3.3-4.9,11.8-53.1-17.3-86-15.9-17.4-42.2-27.1-69.9-27.7-24.5-.5-48.7,10.9-61.6,24.4-33.5,35-20.1,98.2-20.1,98.2.6,10.9,9.1,63.4,21.3,74.6,0,0,33.7,25.7,42.4,30.6a22.71,22.71,0,0,0,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l.2-.2c6.9-9.1,3.9-5.8,11.2-14.8a4.72,4.72,0,0,1,4.8-1.8c4.1.8,11.7,1.3,13.3-7,2.4-11.5,2.6-25.1,8.6-35.5C311.9,191.2,316.1,185,314.1,169.2Z" transform="translate(-0.1)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ear" d="M142.1,236.4c.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48C116,164.1,132,183,132,183" transform="translate(-0.1)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <g id="Ear2"> <path d="M304.4,175.6a10.1,10.1,0,0,1-2.3,3.5c-.9.8-1.7,1.4-2.6,2.2-1.8,1.7-3.9,3.2-5.5,5.2a53.07,53.07,0,0,0-4.2,6.3c-.6,1-1.3,2.2-1.9,3.3l-1.7,3.4-.2-.1,1.4-3.6c.5-1.1.9-2.4,1.5-3.5a57.28,57.28,0,0,1,3.8-6.8,23.79,23.79,0,0,1,5.1-5.9,22.06,22.06,0,0,1,3.2-2.1,12.65,12.65,0,0,0,3.1-2Z" transform="translate(-0.1)"/> </g> <g id="Buste"> <path d="M222.4,340.1c4.6-.4,9.3-.6,13.9-.9l14-.6c4.7-.1,9.3-.3,14-.4l7-.1h7c-2.3.2-4.6.3-7,.5l-7,.4-14,.6c-4.7.1-9.3.3-14,.4C231.8,340.1,227.1,340.2,222.4,340.1Z" transform="translate(-0.1)" fill="#2b232b"/> <path d="M142.5,337.6c4.3,0,8.4.1,12.6.2s8.4.3,12.6.5,8.4.4,12.6.7l6.4.4c2.1.2,4.2.3,6.4.5-2.1,0-4.2,0-6.4-.1l-6.4-.2c-4.2-.1-8.4-.3-12.6-.5s-8.4-.4-12.6-.7C151,338.4,146.9,338,142.5,337.6Z" transform="translate(-0.1)" fill="#2b232b"/> <path d="M199.5,329.6l1.6,3c.5,1,1,2,1.6,3a16,16,0,0,0,1.7,2.8c.2.2.3.4.5.6s.3.2.3.2a3.16,3.16,0,0,0,1.3-.6c1.8-1.3,3.4-2.8,5.1-4.3.8-.7,1.7-1.6,2.5-2.3l2.5-2.3a54.73,54.73,0,0,1-4.4,5.1,27.87,27.87,0,0,1-5.1,4.6,1.64,1.64,0,0,1-.7.4,1.68,1.68,0,0,1-1,.3,1.94,1.94,0,0,1-.7-.2c-.1-.1-.3-.2-.4-.3s-.4-.5-.6-.7c-.6-.9-1.1-2-1.7-3A55,55,0,0,1,199.5,329.6Z" transform="translate(-0.1)" fill="#2b232b"/> <path d="M199.5,329.6s3.5,9.3,5.3,10.1,11.6-10,11.6-10C210.1,331.3,204.2,331.5,199.5,329.6Z" transform="translate(-0.1)" fill-rule="evenodd" opacity="0.19" style="isolation: isolate"/> </g> </g> <g> <line x1="128.4" y1="179.3" x2="134.2" y2="186.7" fill="none"/> <path d="M128.5,179.3a11,11,0,0,1,5.7,7.4A11.61,11.61,0,0,1,128.5,179.3Z" transform="translate(-0.1)"/> </g> </g> <g id="Ring"> <path d="M289,235.1s-4.4,2.1-3.2,6.4c1,4.3,4.4,4,4.8,4a3.94,3.94,0,0,0,3.91-4,1.77,1.77,0,0,0,0-.23" transform="translate(-0.1)" fill="none" stroke="#60d5dc" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> <path d="M137,233.3s-4.4,2.1-3.2,6.4c1,4.3,4.5,3.8,4.8,3.6s1.6.2,3.4-2.3" transform="translate(-0.1)" fill="none" stroke="#52d784" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> </g> <g id="Blood_Long_Hair" data-name="Blood Long Hair"> <g> <polygon points="188.31 114.23 198.41 117.73 211.31 113.93 197.91 102.83 188.31 114.23" fill="#8147b1"/> <polygon points="188.51 114.33 198.41 117.73 211.81 113.83 197.81 103.23 188.51 114.33" opacity="0.5" style="isolation: isolate"/> <path d="M274,199.33c4.2-5.9,10.1-12.8,10.5-18.3,1.1,3.2,2,11.7,1.5,15.8,0,0,5.7-10.8,10.6-15.6,6.4-6.3,13.9-10.2,17.2-14.4,2.3,6.4,1.4,15.3-4.7,28.1,0,0,.4,9.2-.7,15.3,3.3-5.9,12.8-36.2,8.5-61.6,0,0,3.7,9.3,4.4,16.9s3.1-32.8-7.7-51.4c0,0,6.9,3.9,10.8,4.8,0,0-12.6-12.5-13.6-15.9,0,0-14.1-25.7-39.1-34.6,0,0,9.3-3.2,15.6.2-.1-.1-15.1-12.2-34.2-7.1,0,0-15.1-13.6-42.6-12.3l15.6,8.8s-12.9-.9-28.4-1.3c-6.1-.2-21.8,3.3-38.3-1.4,0,0,7.3,7.2,9.4,7.7,0,0-30.6,13.8-47.3,34.2,0,0,10.7-8.9,16.7-10.9,0,0-26,25.2-31.5,70,0,0,9.2-28.6,15.5-34.2,0,0-10.7,27.4-5.3,48.2,0,0,2.4-14.5,4.9-19.2-1,14.1,2.4,33.9,13.8,47.8,0,0-3.3-15.8-2.2-21.9l8.8-17.9a33.3,33.3,0,0,0,3.1,12.3s13-36.1,19.7-43.9c0,0-2.9,15.4-1.1,29.6,0,0,7.2-26.8,17.3-40.1,0,0,.8.1,17.6-7.6,6.3,3.1,8,1.4,17.9,7.7,4.1,5.3,13.8,31.9,15.6,41.5,3.4-7.3,5.6-19,5.2-29.5,2.7,3.7,8.9,19.9,9.6,34.3,4.3-6,6.4-27.8,5.9-29,0,1.2.2,14.8.3,14.3,0,0,12.1,19.9,14.9,19.7,0-.8-1.7-12.9-1.7-12.8,1.3,5.8,2.8,23.3,3.1,27.1l5-9.5C274.91,174.93,275.71,193.23,274,199.33Z" transform="translate(-0.1)" fill="#bfd2d3" stroke="#000" stroke-miterlimit="10" stroke-width="2"/> <g> <path d="M295.51,180.93" transform="translate(-0.1)" fill="none" stroke="#000" stroke-miterlimit="10" stroke-width="0.5"/> <path d="M286.91,199.63" transform="translate(-0.1)" fill="none" stroke="#000" stroke-miterlimit="10" stroke-width="0.5"/> <path d="M133.41,180s-1.3-11.3.3-16.9" transform="translate(-0.1)" fill="none" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="2"/> <path d="M142.41,159.63s-1-6.5,1.6-20.4" transform="translate(-0.1)" fill="none" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="2"/> </g> </g> <g id="Shadow"> <path d="M180.81,117.83s-15.9,23.7-16.9,25.6,0,12.4.3,12.8S166,141.23,180.81,117.83Z" transform="translate(-0.1)" fill-rule="evenodd" opacity="0.2" style="isolation: isolate"/> <path d="M164.81,127.63s-16.3,25.3-17.9,26.3c0,0-3.8-12.8-3-14.7s-9.6,10.3-9.9,17c0,0-8.4-.6-11-7.4-1-2.5,1.4-9.1,2.1-12.2,0,0-6.5,7.9-9.4,22.5,0,0,.6,8.8,1.1,10,0,0,3.5-14.8,4.9-17.7,0,0-.3,33.3,13.6,46.7,0,0-3.7-18.6-2.6-21l9.4-18.6s2.1,10.5,3.1,12.3l13.9-33.1Z" transform="translate(-0.1)" opacity="0.2" style="isolation: isolate"/> <path d="M253.51,145.53c.8,4.4,8.1,12.1,13.1,11.7l1.6,11s-5.2-3.9-14.7-19.9Z" transform="translate(-0.1)" opacity="0.16" style="isolation: isolate"/> <path d="M237.81,129s4.4,3,13.9,21.7c0,0-4.3,12-4.6,12.4S248.71,152.43,237.81,129Z" transform="translate(-0.1)" opacity="0.16" style="isolation: isolate"/> <path d="M221.21,126.33s5.2,4,14.4,23a67.2,67.2,0,0,1-3.1,8.9C227.91,142,227.31,139.53,221.21,126.33Z" transform="translate(-0.1)" opacity="0.17" style="isolation: isolate"/> <path d="M272.31,142.43c-2.4,8.1-3.6,13.8-4.9,17.9,0,0,1.3,12.8,2.1,22.2,4.7-8.4,4.7-8.4,5.4-9,.2.6,3.1,11.9-1.2,26.6,5.1-6.7,10.4-14.9,11-21.3,1.1,3.7,1.7,15,1.2,19.1a132,132,0,0,1,12.3-11.3s8.7-3.5,12.5-7.2c0,0,2.2,1.4-1.2,11.6l3.7-8s-2.7,19.9-3.4,22.5c0,0,9.8-33.3,7.2-58,0,0,4.7,8.3,4.9,17.1s1.7-8.6.2-17.8c0,0-6.5-13.9-8.2-15.4,0,0,1.3,10.1.4,13.6,0,0-7.3-10.3-10.5-12.5,0,0,1.1,30.2-1.7,35.3,0,0-6.1-17-10.7-20.8,0,0-2.4,20.9-5.6,28.1C283.91,172.83,280.71,156.53,272.31,142.43Z" transform="translate(-0.1)" opacity="0.2" style="isolation: isolate"/> <path d="M198.41,104.83c-.9-3.9,3.2-35.1,34.7-36C227.81,68.13,199.11,89.43,198.41,104.83Z" transform="translate(-0.1)" opacity="0.14" style="isolation: isolate"/> </g> <g id="Light" opacity="0.64"> <path d="M128.31,114.43s9.5-20.6,23.5-27.7A227.78,227.78,0,0,0,128.31,114.43Z" transform="translate(-0.1)" fill="#fff"/> <path d="M302.61,117.33s-12.8-26.4-29.7-35A149.66,149.66,0,0,1,302.61,117.33Z" transform="translate(-0.1)" fill="#fff"/> <path d="M251.61,126.23s-9.2-18.7-11.6-21.1,5,1.8,12.2,20.3" transform="translate(-0.1)" fill="#fff"/> <path d="M168.51,102.43s-10.7,10.8-16,23.9C157.71,116.73,168.51,102.43,168.51,102.43Z" transform="translate(-0.1)" fill="#fff"/> <path d="M170.31,124.83s7.5-21.3,8.4-22.5-12.6,11.4-13.1,18c0,0,9-12.8,9.5-13.5S169.11,120.53,170.31,124.83Z" transform="translate(-0.1)" fill="#fff"/> <path d="M233.41,126.33s-7.5-21.3-8.4-22.5,12.6,11.4,13.1,18c0,0-9-12.8-9.5-13.5S234.61,122,233.41,126.33Z" transform="translate(-0.1)" fill="#fff"/> </g> </g> <g id="Eyebrow"> <g id="Kitsune"> <path d="M239.6,170.4c-11.8-4.7-18.7-2.3-21-1.2-.1,0-.2.1-.3.2-.3.1-.5.3-.6.3h0a4.37,4.37,0,0,0-1.8,3.1,4.6,4.6,0,0,0,3.81,5.27l.19,0h.2a4.75,4.75,0,0,0,5.4-4V174a3.37,3.37,0,0,0,.1-1C230.3,169.5,239.6,170.4,239.6,170.4Z" transform="translate(-0.1)" fill-rule="evenodd"/> <path d="M164.4,169.9c12-4.1,18.8-1.5,21.1-.2.1,0,.2.1.3.2a2.17,2.17,0,0,1,.6.4h0a5.53,5.53,0,0,1,1.7,3.2,4.79,4.79,0,0,1-4.4,5.1h0a5.11,5.11,0,0,1-5.3-4.4v-1C173.8,169.4,164.4,169.9,164.4,169.9Z" transform="translate(-0.1)" fill-rule="evenodd"/> </g> <g id="Kitsune-2" data-name="Kitsune"> <path d="M239.6,170.4c-11.8-4.7-18.7-2.3-21-1.2-.1,0-.2.1-.3.2-.3.1-.5.3-.6.3h0a4.37,4.37,0,0,0-1.8,3.1,4.6,4.6,0,0,0,3.81,5.27l.19,0h.2a4.75,4.75,0,0,0,5.4-4V174a3.37,3.37,0,0,0,.1-1C230.3,169.5,239.6,170.4,239.6,170.4Z" transform="translate(-0.1)" fill="#2f3555" fill-rule="evenodd"/> <path d="M164.4,169.9c12-4.1,18.8-1.5,21.1-.2.1,0,.2.1.3.2a2.17,2.17,0,0,1,.6.4h0a5.53,5.53,0,0,1,1.7,3.2,4.79,4.79,0,0,1-4.4,5.1h0a5.11,5.11,0,0,1-5.3-4.4v-1C173.8,169.4,164.4,169.9,164.4,169.9Z" transform="translate(-0.1)" fill="#2f3555" fill-rule="evenodd"/> </g> </g> <g id="Eyes"> <g id="Pupils"> <g> <g id="No_Fill" data-name="No Fill"> <g> <path d="M219.3,197.7s3.1-22.5,37.9-15.5C257.3,182.1,261.2,209.2,219.3,197.7Z" transform="translate(-0.1)" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M227.5,182.5a13.21,13.21,0,0,0-2.7,2c-.8.7-1.6,1.6-2.3,2.3a26.45,26.45,0,0,0-2.1,2.5l-1,1.4c-.3.4-.6.9-1,1.4.2-.5.4-1,.6-1.6a11.94,11.94,0,0,1,.8-1.6,17.47,17.47,0,0,1,4.7-5.1A4.82,4.82,0,0,1,227.5,182.5Z" transform="translate(-0.1)" fill="#2f3555"/> <path d="M245.6,201.3a14.92,14.92,0,0,0,3.6-1,19.73,19.73,0,0,0,3.2-1.8,16.41,16.41,0,0,0,2.7-2.5c.8-1,1.6-2,2.3-3a7.7,7.7,0,0,1-1.7,3.5,12.4,12.4,0,0,1-2.8,2.8,11.37,11.37,0,0,1-3.5,1.7A7,7,0,0,1,245.6,201.3Z" transform="translate(-0.1)" fill="#2f3555"/> </g> <g> <path d="M184.1,197.7s-3.1-22.5-37.9-15.5C146.2,182.1,142.2,209.2,184.1,197.7Z" transform="translate(-0.1)" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M176,182.5a13.21,13.21,0,0,1,2.7,2c.8.7,1.6,1.6,2.3,2.3a26.45,26.45,0,0,1,2.1,2.5l1,1.4c.3.4.6.9,1,1.4-.2-.5-.4-1-.6-1.6a11.94,11.94,0,0,0-.8-1.6,17.47,17.47,0,0,0-4.7-5.1A5.47,5.47,0,0,0,176,182.5Z" transform="translate(-0.1)" fill="#2f3555"/> <path d="M157.8,201.3a14.92,14.92,0,0,1-3.6-1,19.73,19.73,0,0,1-3.2-1.8,16.41,16.41,0,0,1-2.7-2.5c-.8-1-1.6-2-2.3-3a7.7,7.7,0,0,0,1.7,3.5,12.4,12.4,0,0,0,2.8,2.8A11.37,11.37,0,0,0,154,201,8.16,8.16,0,0,0,157.8,201.3Z" transform="translate(-0.1)" fill="#2f3555"/> </g> </g> <g id="Shadow-2" data-name="Shadow" opacity="0.43"> <path d="M218.5,192s4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8C219.1,184.2,218.5,192,218.5,192Z" transform="translate(-0.1)" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> <g id="Shadow-3" data-name="Shadow" opacity="0.43"> <path d="M185.1,191.7s-4.8-10.6-20.1-13.4c0,0,12.4-.2,16.3,2.6C184.6,184,185.1,191.7,185.1,191.7Z" transform="translate(-0.1)" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> </g> </g> <g id="Moon"> <path id="Moon_Aka" data-name="Moon Aka" d="M246.5,190.9a5.62,5.62,0,0,0-2.4-4.9,4,4,0,0,1,1.1,3.1,4.64,4.64,0,0,1-4.7,4.4A4.49,4.49,0,0,1,236,189v-.14a3.76,3.76,0,0,1,1.4-3,5.6,5.6,0,0,0-2.6,4.7,5.85,5.85,0,1,0,11.7.3Z" transform="translate(-0.1)" fill="#60d5dc"/> <path id="Moon_Aka-2" data-name="Moon Aka" d="M169.8,191.1a5.62,5.62,0,0,0-2.4-4.9,4,4,0,0,1,1.1,3.1,4.64,4.64,0,0,1-4.7,4.4,4.49,4.49,0,0,1-4.5-4.46v-.14a3.76,3.76,0,0,1,1.4-3,5.6,5.6,0,0,0-2.6,4.7,5.72,5.72,0,0,0,5.54,5.9h.16a5.7,5.7,0,0,0,6-5.38v-.22Z" transform="translate(-0.1)" fill="#52d784"/> </g> </g> <g id="Mouth"> <g id="Monster"> <path d="M165.7,242.3l1.4.3c4.3,1.2,36.4,12.1,81.4-1,.1.1-17.5,28.2-43.1,28.6C192.6,270.5,181.3,263.8,165.7,242.3Z" transform="translate(-0.1)" fill="#fff" stroke="#2f3555" stroke-miterlimit="10" stroke-width="0.75"/> <polyline points="168.7 246.2 171.4 244 174 253 177.6 245.5 181.8 260.8 188.3 247.2 192.9 267.7 198.6 248.2 204.1 270.3 209.1 248.3 215.6 268.7 219.4 247.5 225.5 264.4 228.3 246.4 234.1 258.2 236.8 244.9 240.5 251.8 243.2 243.1 246 245.5" fill="none" stroke="#2f3555" stroke-linejoin="round" stroke-width="0.75"/> <g opacity="0.52"> <path d="M246.3,239.9a31.46,31.46,0,0,1,5.9-1.9l.6-.1-.2.6c-.6,2.2-1.3,4.4-2.1,6.5a55.85,55.85,0,0,1,1.4-6.9l.4.5A17.45,17.45,0,0,1,246.3,239.9Z" transform="translate(-0.1)"/> </g> <g opacity="0.52"> <path d="M168.2,240.8c-2-.2-4-.5-5.9-.8l.4-.5a46.5,46.5,0,0,1,1.5,7.2,56.82,56.82,0,0,1-2.2-7l-.2-.6.6.1A29.16,29.16,0,0,1,168.2,240.8Z" transform="translate(-0.1)"/> </g> </g> </g> <g id="Accessoire"> <g id="Bloody_Horn" data-name="Bloody Horn"> <g> <path d="M255.8,94.9s36.9-18,49.2-42.8c0,0-1.8,38.5-25.6,68.6C268,114.9,259.8,106.3,255.8,94.9Z" transform="translate(-0.1)" fill="#60d5dc" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M256.9,95.2c-.1.2,4.3,18.1,22.8,24.4" transform="translate(-0.1)" fill="none" stroke="#60d5dc" stroke-miterlimit="10" stroke-width="2"/> </g> <g> <path d="M160.7,94.4s-36.9-18.1-49.2-43c0,0,1.8,38.6,25.6,68.9C148.5,114.5,156.7,105.8,160.7,94.4Z" transform="translate(-0.1)" fill="#52d784" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M159.9,94.5c.1.2-5.1,19-22.9,24.5" transform="translate(-0.1)" fill="none" stroke="#52d784" stroke-miterlimit="10" stroke-width="2"/> </g> </g> </g> <g id="Mask"> <g id="Strap"> <path id="Classic" d="M175,307.2s22.1,16.3,86.9.5c0,0-.5-15.3,4.6-47.1L283,239.3s-46-28.7-83.5-38.3c-1.1-.3-3.1-.7-4.2-.2-19.9,8.4-54.1,34.8-54.1,34.8s9,20.8,10.8,23.4c1.4,2,23.1,18.5,23.1,18.5s.7.2.7.3C176,279,177.3,287.1,175,307.2Z" transform="translate(-0.1)" stroke="#000" stroke-miterlimit="10" fill="url(#linear-gradient)"/> <path d="M176,278.1s21.3,17.6,29.6,17.9,15.7-4,16.6-4.5,19-9.1,33.1-20.7m11.9-11a112.61,112.61,0,0,1-11.9,11" transform="translate(-0.1)" fill="none" stroke="#000" stroke-linecap="round" stroke-miterlimit="10"/> <path d="M199.7,232l-8.2-3.6a.78.78,0,0,1-.3-1,.09.09,0,0,1,.1-.1h0l3.3-3.4a1.56,1.56,0,0,1,1.6-.3l13.2,4.8a.83.83,0,0,1,.4,1,1,1,0,0,1-.5.4l-9.1,2.5C200,232.1,199.7,232.1,199.7,232Zm-24,46.6s26.5,36.4,43.2,32,43.7-21.8,43.7-21.8c1.3-9.1,2.2-19.7,3.3-28.7-4.8,4.9-13.3,13.8-21.8,19.1-5.2,3.2-22.1,15.1-36.4,16.7C200.2,296.7,175.7,278.6,175.7,278.6Z" transform="translate(-0.1)" opacity="0.21" style="isolation: isolate"/> <path d="M142.4,237.9c35.7-22.7,64-30.2,98.5-21.1m30.6,36.9c-21.9-16.9-64.5-38-78.5-32.4-13.3,7.4-37,18-46.8,25.3m88-15.4c-33.8,2.6-57.2.1-84.7,23.6M265,262c-20.5-14.5-48.7-25.1-73.9-27m23,3.8c-19.3,2-43.6,11.7-59.1,22.8m106.1,4.2c-47.9-12.4-52.5-26.6-98,2.8m69.2-11.5c-20.7.3-43.9,9.9-63.3,16.4m72.4,7.2c-11.5-4.1-40.1-14.8-52.5-14.2m28.3,6c-10.7-2.9-24,7.9-32,13.1m39.3,4.8c-4-5.7-23-7.4-28.1-11.9m-20.7,23.9c4.3,3.8,21.4,7.3,39.5,7.2,18.5-.1,38.1-4,46.6-8.6m-85.2-6.6c11.6,3.8,18.2,7.3,38.1,5.9,15.1-1,34.3-4,47.8-10.7m-40.4,1.9c9.4,0,32-5.9,40.8-8.8m-21.8-2c3.4.4,20-5.4,23.6-6.8m-47-60.8a145.57,145.57,0,0,0-19.8-3.2c-5-.3-15.5-.2-20.6.6" transform="translate(-0.1)" fill="none" stroke="#000" stroke-miterlimit="10"/> </g> </g> </svg>';
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