interface RefreshIconProps {
  className?: string;
}

export const RefreshIcon = ({ className }: RefreshIconProps) => {
  return (
    <svg
      className={className}
      width="16"
      height="16"
      viewBox="0 0 1536 1536"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <title>Refresh</title>
      <path
        fill="currentColor"
        d="M1511 928q0 5-1 7q-64 268-268 434.5T764 1536q-146 0-282.5-55T238 1324l-129 129q-19 19-45 19t-45-19t-19-45V960q0-26 19-45t45-19h448q26 0 45 19t19 45t-19 45l-137 137q71 66 161 102t187 36q134 0 250-65t186-179q11-17 53-117q8-23 30-23h192q13 0 22.5 9.5t9.5 22.5zm25-800v448q0 26-19 45t-45 19h-448q-26 0-45-19t-19-45t19-45l138-138Q969 256 768 256q-134 0-250 65T332 500q-11 17-53 117q-8 23-30 23H50q-13 0-22.5-9.5T18 608v-7q65-268 270-434.5T768 0q146 0 284 55.5T1297 212l130-129q19-19 45-19t45 19t19 45z"
      />
    </svg>
  );
};
