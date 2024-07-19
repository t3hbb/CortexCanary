import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.HashSet;
import java.util.Set;
import java.util.TreeSet;

public class DirectoryListingComparison {

    public static void main(String[] args) {
        String directoryPath = null;

        // Process command line switches
        for (int i = 0; i < args.length; i++) {
            if ("-d".equals(args[i]) && i + 1 < args.length) {
                directoryPath = args[i + 1];
                i++; // skip the directory path in the next iteration
            }
        }

        if (directoryPath == null) {
            System.out.println("Usage: java DirectoryListingComparison -d <directory>");
            return;
        }

        // Perform directory listing using Java
        Set<String> javaListing = getDirectoryListingJava(directoryPath);

        // Perform directory listing using cmd.exe and dir
        Set<String> cmdListing = getDirectoryListingCmd(directoryPath);

        // Ignore desktop.ini in Java output
        javaListing.remove("desktop.ini");

        // Find the files/directories present in Java output but not in cmd output
        Set<String> difference = new TreeSet<>(javaListing);
        difference.removeAll(cmdListing);

        // Output the difference
        System.out.println("Files/Directories present in Java output but not in cmd output:");
        for (String item : difference) {
            File file = new File(directoryPath, item);
            String itemType = file.isDirectory() ? "Directory" : "File";
            long size = file.length();
            String lastModified = new SimpleDateFormat("dd-MM-yyyy HH:mm:ss").format(file.lastModified());
            System.out.printf("%-30s %-10s %-10d bytes  Last Modified: %s%n", item, itemType, size, lastModified);
        }
    }

    // Perform directory listing using Java
    private static Set<String> getDirectoryListingJava(String directoryPath) {
        Set<String> listing = new HashSet<>();
        File directory = new File(directoryPath);

        if (directory.exists() && directory.isDirectory()) {
            String[] contents = directory.list();
            if (contents != null) {
                for (String item : contents) {
                    listing.add(item);
                }
            }
        }
        return listing;
    }

    // Perform directory listing using cmd.exe and dir
    private static Set<String> getDirectoryListingCmd(String directoryPath) {
        Set<String> listing = new HashSet<>();
        try {
            Process process = Runtime.getRuntime().exec("cmd.exe /c dir /b \"" + directoryPath + "\"");
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                listing.add(line);
            }
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
        return listing;
    }
}
