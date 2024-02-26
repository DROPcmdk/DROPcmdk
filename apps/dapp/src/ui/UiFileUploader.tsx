import { ChangeEvent, SyntheticEvent } from 'react';
import { FiUpload } from 'react-icons/fi';
import { UiSpinner } from './UiSpinner';

interface UiFileUploaderProps {
  uploadFunction: (
    e: SyntheticEvent | ChangeEvent<HTMLInputElement>,
  ) => Promise<void>;

  loadingState: boolean;
  fileName?: string;
  innerText?: string;
  errorMessage?: string;
  accept?: string;
  multiple?: boolean;
}

export default function UiFileUploader({
  uploadFunction,
  loadingState,
  fileName,
  innerText,
  errorMessage,
}: UiFileUploaderProps) {
  return (
    <label
      className="flex flex-row h-10 w-60 rounded-md border border-black justify-between items-center"
      onDrop={uploadFunction}
      onDragOver={(e) => e.preventDefault()}
    >
      {errorMessage ? (
        <h3 className="font-bold ml-6 text-black italic">{errorMessage}</h3>
      ) : (
        <h3 className="font-bold ml-6 max-w-40 truncate">
          {fileName ? fileName : innerText}
        </h3>
      )}
      <div className="flex flex-col cursor-pointer items-center justify-center h-10 w-10 border-l border-black rounded-md">
        {loadingState ? (
          <UiSpinner />
        ) : (
          <div>
            <FiUpload className="h-6 w-6" />

            <input
              type="file"
              className="hidden"
              onChange={uploadFunction}
              accept=".jpg, .jpeg, image/jpeg, .png, image/png"
            />
          </div>
        )}
      </div>
    </label>
  );
}
