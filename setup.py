from setuptools import setup, find_packages

setup(
    name="AndroByte",
    version="0.1.0",
    description="Android bytecode privacy analysis and summarization tool",
    author="Name",
    packages=find_packages(include=["parser", "summarizer"]),
    install_requires=[
        "androguard==4.1.3",
        "networkx==3.2.1",
        "matplotlib==3.8.4",
        "graphviz==0.20.3",
        "requests==2.31.0"
    ],
    entry_points={
        "console_scripts": [
            "androbyte=run_pipeline:main"
        ]
    },
    python_requires='>=3.9',
    include_package_data=True,
    zip_safe=False
)
