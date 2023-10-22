import pandas as pd
import numpy as np

# Define the file path of your CSV file
csv_file = "output of the measurement_final.csv"

# Read the CSV file into a DataFrame
df = pd.read_csv(csv_file)

# Define the columns you want to extract
columns_to_extract = ['stats_area_mean_1', 'stats_diameter_mean_1', "stats_hydraulicD_mean_1", "stats_tortuosity",  "stats_arclength", "stats_euclength", "stats_volume_1",]

# Create a new DataFrame with only the selected columns
selected_columns_df = df[columns_to_extract]

# Rename columns
selected_columns_df = selected_columns_df.rename(columns={'stats_area_mean_1': 'area',
                                                          'stats_diameter_mean_1': 'diameter',
                                                          'stats_hydraulicD_mean_1': 'hydraulic_diameter',
                                                          'stats_tortuosity': 'tortuosity',
                                                          "stats_arclength" : "arc_length",
                                                          "stats_euclength" : "euc_length",
                                                          'stats_volume_1': 'volume'})

# Calculate the average, median, minimum, and maximum for each column
column_stats = selected_columns_df.agg(['mean', 'median', 'min', 'max'])
column_stats.index.name = f"(number of tubes: {len(df)})"
column_stats.to_csv("summary statistics.csv", index=True)